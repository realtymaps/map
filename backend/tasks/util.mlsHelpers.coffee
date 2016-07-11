_ = require 'lodash'
Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
dbs = require '../config/dbs'
logger = require('../config/logger').spawn('task:mls')
finePhotologger = logger.spawn('photos.fine')
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
retsService = require '../services/service.rets'
dataLoadHelpers = require './util.dataLoadHelpers'
rets = require 'rets-client'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
awsService = require '../services/service.aws'
mlsPhotoUtil = require '../utils/util.mls.photos'
uuid = require '../utils/util.uuid'
externalAccounts = require '../services/service.externalAccounts'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
config = require '../config/config'
internals = require './util.mlsHelpers.internals'
analyzeValue = require '../../common/utils/util.analyzeValue'
jobQueue = require '../services/service.jobQueue'
mlsConfigService = require '../services/service.mls_config'


ONE_YEAR_MILLIS = 365*24*60*60*1000


# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options={}) ->
  # figure out when we last got updates from this table
  updateThresholdPromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
  uuidPromise = internals.getUuidField(subtask.task_name)
  Promise.join updateThresholdPromise, uuidPromise, (updateThreshold, uuidField) ->
    retsService.getDataStream(subtask.task_name, minDate: updateThreshold, uuidField: uuidField, searchOptions: {limit: options.limit})
    .catch retsService.isTransientRetsError, (error) ->
      throw new SoftFail(error, "Transient RETS error; try again later")
    .then (retsStream) ->
      rawTableName = tables.temp.buildTableName(dataLoadHelpers.buildUniqueSubtaskName(subtask))
      dataLoadHistory =
        data_source_id: options.dataSourceId
        data_source_type: 'mls'
        data_type: 'listing'
        batch_id: subtask.batch_id
        raw_table_name: rawTableName
      dataLoadHelpers.manageRawDataStream(rawTableName, dataLoadHistory, retsStream)
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to load RETS data for update')


buildRecord = (stats, usedKeys, rawData, dataType, normalizedData) -> Promise.try () ->
  # build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(base.address)
    hide_listing: base.hide_listing ? false
    hide_address: base.hide_address ? false
    shared_groups:
      general: normalizedData.general || []
      details: normalizedData.details || []
      listing: normalizedData.listing || []
      building: normalizedData.building || []
      dimensions: normalizedData.dimensions || []
      lot: normalizedData.lot || []
      location: normalizedData.location || []
      restrictions: normalizedData.restrictions || []
    subscriber_groups:
      contacts: normalizedData.contacts || []
      realtor: normalizedData.realtor || []
      sale: normalizedData.sale || []
    hidden_fields: dataLoadHelpers.getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
    deleted: null
  _.extend base, stats, data


finalizeData = ({subtask, id, data_source_id, finalizedParcel, transaction, delay}) ->
  delay ?= 100
  parcelHelpers = require './util.parcelHelpers'#delayed require due to circular dependency

  listingsPromise = tables.normalized.listing()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .where(hide_listing: false)
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderBy('hide_listing')
  .orderByRaw('close_date DESC NULLS FIRST')
  parcelPromise = if finalizedParcel? then Promise.resolve([finalizedParcel]) else parcelHelpers.getParcelsPromise {rm_property_id: id, transaction}
  Promise.join listingsPromise, parcelPromise, (listings=[], parcel=[]) ->
    if listings.length == 0
      logger.spawn(subtask.task_name).debug "No listings found for rm_property_id: #{id}"
      # might happen if a singleton listing is changed to hidden during the day
      return dataLoadHelpers.markForDelete(id, subtask.task_name, subtask.batch_id, {transaction})

    listing = dataLoadHelpers.finalizeEntry({entries: listings, subtask})
    listing.data_source_type = 'mls'
    _.extend(listing, parcel[0])
    Promise.delay(delay)  #throttle for heroku's sake
    .then () ->
      # do owner name and zoning promotion logic
      if listing.owner_name? || listing.owner_name_2? || listing.zoning
        # keep previously-promoted values
        return false
      dataLoadHelpers.checkTableExists('normalized', tables.normalized.tax.buildTableName(listing.fips_code))
    .then (checkPromotedValues) ->
      if !checkPromotedValues
        return
      # need to query the tax table to get values to promote
      tables.normalized.tax(subid: listing.fips_code)
      .select('promoted_values')
      .where
        rm_property_id: id
      .then (results=[]) ->
        if results[0]?.promoted_values
          # promote values into this listing
          _.extend(listing, results[0].promoted_values)
          # save back to the listing table to avoid making checks in the future
          tables.normalized.listing()
          .where
            data_source_id: listing.data_source_id
            data_source_uuid: listing.data_source_uuid
          .update(results[0].promoted_values)
    .then () ->
      dbs.ensureTransaction transaction, 'main', (transaction) ->
        tables.finalized.combined(transaction: transaction)
        .where
          rm_property_id: id
          data_source_id: data_source_id || subtask.task_name
          active: false
        .delete()
        .then () ->
          tables.finalized.combined(transaction: transaction)
          .insert(listing)


_updatePhoto = (subtask, opts) -> Promise.try () ->
  if !opts
    logger.spawn(subtask.task_name).debug 'GTFO: _updatePhoto'
    return

  onMissingArgsFail
    args: opts
    required: ['newFileName', 'imageId', 'photo_id', 'listingRow']

  {newFileName, imageId, photo_id, listingRow, objectData, transaction} = opts
  externalAccounts.getAccountInfo(config.EXT_AWS_PHOTO_ACCOUNT)
  .then (s3Info) ->
    ###
    Update photo's hash in a listing col
    example:
      photos:
        1: https://s3.amazonaws.com/uuid/swflmls/mls_id_1.jpeg
        2: https://s3.amazonaws.com/uuid/swflmls/mls_id_2.jpeg
        3: https://s3.amazonaws.com/uuid/swflmls/mls_id_1.jpeg
    ###
    obj =
      key: newFileName
      url: "#{config.S3_URL}/#{s3Info.other.bucket}/#{newFileName}"


    obj.objectData = objectData if objectData

    jsonObjStr = JSON.stringify obj

    finePhotologger.debug jsonObjStr

    cdnPhotoStrPromise = Promise.resolve('')
    if imageId == 0
      cdnPhotoStrPromise = mlsPhotoUtil.getCndPhotoShard(opts)

    cdnPhotoStrPromise
    .then (cdnPhotoStr) ->

      internals.makeInsertPhoto {
        listingRow
        cdnPhotoStr
        jsonObjStr
        imageId
        photo_id
        transaction
      }

    .catch (error) ->
      logger.spawn(subtask.task_name).error error
      logger.spawn(subtask.task_name).debug 'Handling error by enqueuing photo to be deleted.'
      _enqueuePhotoToDelete(obj.key, subtask.batch_id, {transaction})

_enqueuePhotoToDelete = (key, batch_id, {transaction}) ->
  if key?
    tables.deletes.photos({transaction})
    .insert {key, batch_id}
  else
    Promise.resolve()

###
  using upload see service.aws.putObject comments

  The short of it is that we do not know the size of the payload. EVEN if rets-client gives a size if it is invalid
  it causes too many problems. It is easier to forgoe worying about size and just upload blindly!
###
_uploadPhoto = ({photoRes, newFileName, payload, row}) ->
  new Promise (resolve, reject) ->
    awsService.upload
      extAcctName: config.EXT_AWS_PHOTO_ACCOUNT
      Key: newFileName
      ContentType: payload.contentType
      Metadata:
        data_source_id: row.data_source_id
        data_source_uuid: row.data_source_uuid
        rm_property_id: row.rm_property_id
        height: photoRes.height
        width: photoRes.width
    .then (upload) ->

      payload.data.once 'error', (error) ->
        reject error

      upload.once 'uploaded', (details) ->
        logger.spawn(row.data_source_id).debug details
        resolve(details)

      upload.once 'error', (error) ->
        reject error

      payload.data.pipe(upload)

    .catch (error) -> #missing catch
      reject error

storePhotos = (subtask, listingRow) -> Promise.try () ->
  finePhotologger.debug subtask.task_name
  finePhotologger.debug listingRow, true

  mlsConfigPromise = mlsConfigService.getByIdCached(subtask.task_name)
  listingRowPromise = tables.normalized.listing()
  .where(listingRow)
  Promise.join mlsConfigPromise, listingRowPromise, (mlsConfig, rows) ->

    if !rows.length
      finePhotologger.debug 'No rows GTFO'
      return Promise.resolve()

    [row] = rows
    finePhotologger.debug "id: data_source_id: #{listingRow.data_source_id} data_source_uuid: #{listingRow.data_source_uuid}"

    #if the photo set is not updated GTFO
    logger.spawn(subtask.task_name).debug row.photo_last_mod_time

    if row.photo_last_mod_time? && row.photo_download_last_mod_time? &&
    row.photo_last_mod_time == row.photo_download_last_mod_time
      finePhotologger.debug 'photo_last_mod_time identical  GTFO'
      return Promise.resolve()

    {photo_id} = row
    photoIds = {}
    #get all photos for a specific property
    photoIds[photo_id] = '*'

    finePhotologger.debug photoIds

    photoType = mlsConfig.listing_data.largestPhotoObject
    {photoRes} = mlsConfig.listing_data

    retsService.getPhotosObject {
      mlsId: subtask.task_name
      databaseName: 'Property'
      photoIds
      photoType
    }
    .then (obj) ->
      successCtr = 0
      errorsCtr = 0
      skipsCtr = 0
      promises = []

      savesPromise = new Promise (resolve, reject) ->
        mlsPhotoUtil.imagesHandle obj, (err, payload, isEnd) ->

          if err
            console.log("error in mlsHelpers#storePhotos from imagesHandle: #{err}")
            logger.spawn(subtask.task_name).debug 'ERROR: rets-client getObjects!!!!!!!!!!!!!'
            return reject err

          if isEnd
            return resolve(Promise.all promises)

          #file naming consideratons
          #http://docs.aws.amazon.com/AmazonS3/latest/dev/request-rate-perf-considerations.html
          newFileName = "#{uuid.genUUID()}/#{subtask.task_name}/#{payload.name}"
          {imageId, objectData} = payload

          logger.spawn(subtask.task_name).debug _.omit payload, 'data'

          if mlsPhotoUtil.hasSameUploadDate(objectData?.uploadDate, row.photos[imageId]?.objectData?.uploadDate)
            skipsCtr++
            finePhotologger.debug 'photo has same updateDate GTFO.'
            return

          uploadPromise = dbs.transaction 'normalized', (transaction1) ->
            _updatePhoto(subtask, {newFileName, imageId, photo_id, objectData, listingRow, transaction: transaction1})
            .catch (error) ->
              console.log("SPAM error catching 3: #{error}")
            .then () ->
              dbs.transaction 'main', (transaction2) ->
                _enqueuePhotoToDelete(row.photos[imageId]?.key, subtask.batch_id, transaction: transaction2)
                .catch (error) ->
                  console.log("SPAM error catching 2: #{error}")
                .then () ->
                  _uploadPhoto({photoRes, newFileName, payload, row})
                  .catch (error) ->
                    console.log("SPAM error catching 1: #{error}")
              .catch (error) ->
                console.log("SPAM error catching 4: #{error}")
            .catch (error) ->
              console.log("SPAM error catching 5: #{error}")
          .catch (error) ->
            console.log("SPAM error catching 6: #{error}")
          .then () ->
            logger.spawn(subtask.task_name).debug 'photo upload success'
            successCtr++
          .catch (error) ->
            # TODO: 1) investigate NO_OBJECT_FOUND error (can be detected based on ReplyCode: 20403) and figure out when
            # TODO:    it occurs; maybe for listings with no photos?  if so, then we should not really treat it as an
            # TODO:    error, especially for the retry logic described in a TODO below
            # TODO: 2) investigate duplicate key error for inserts into delete_photos -- seems like that shouldn't be
            # TODO:    possible, so it could be an indication of a deeper bug
            console.log("upload error in mlsHelpers#storePhotos (was: #{row.photos[imageId]?.key}, now: #{newFileName}): #{error}")
            logger.spawn(subtask.task_name).debug 'ERROR: putObject!!!!!!!!!!!!!!!!'
            logger.spawn(subtask.task_name).debug analyzeValue.getSimpleDetails(error)
            errorsCtr++
            #record the error, enqueue a delete for the new version just in case, and move on
            tables.normalized.listing()
            .where(listingRow)
            .update(photo_import_error: analyzeValue.getSimpleDetails(error))
          promises.push(uploadPromise)
      savesPromise
      .catch (err) ->
        console.log("SPAM error catching 12: #{err}")
      .then () ->
        logger.spawn(subtask.task_name).debug "Uploaded #{successCtr} photos to aws bucket."
        logger.spawn(subtask.task_name).debug "Skipped #{skipsCtr} photos to aws bucket."
        logger.spawn(subtask.task_name).debug "Failed to upload #{errorsCtr} photos to aws bucket."
        # TODO: 3) if we had transient errors on 1 or more of the images for this listing (or for
        # TODO:    retsService.getPhotosObject overall), record this listing somehow for a later retry.  The retry
        # TODO:    should probably be handled in storePhotosPrep, which would need to enqueue any recorded listings for
        # TODO:    this MLS from prior batches in addition to what it does now (listings inserted/updated during this
        # TODO:    batch).  Then we would also need another subtask at the end of the mls task that clears out any
        # TODO:    recorded listings for this mls from prior batches (since if the transient error was still happening,
        # TODO:    it would have been recorded again for this batch)
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'problem storing photo')
    .catch (error) ->
      console.log("overall error in mlsHelpers#storePhotos: #{error}")
      tables.normalized.listing()
      .where(listingRow)
      .update photo_import_error: analyzeValue.getSimpleDetails(error)

deleteOldPhoto = (subtask, key) -> Promise.try () ->
  logger.spawn(subtask.task_name).debug "deleting: photo with key: #{key}"

  awsService.deleteObject
    extAcctName: config.EXT_AWS_PHOTO_ACCOUNT
    Key: key
  .then () ->
    logger.spawn(subtask.task_name).debug 'successful deletion of aws photo ' + key

    tables.deletes.photos()
    .where {key}
    .del()
    .catch (error) ->
      throw new SoftFail(error, "Transient Photo Deletion error; try again later. Failed to delete from database.")
  .catch (error) ->
    throw new SoftFail(error, "Transient AWS Photo Deletion error; try again later")


markUpToDate = (subtask) ->
  internals.getUuidField(subtask.task_name)
  .then (uuidField) ->
    dataOptions = {uuidField, minDate: 0, searchOptions: {limit: subtask.data.limit, Select: uuidField, offset: 1}}
    retsService.getDataChunks subtask.task_name, dataOptions, (chunk) -> Promise.try () ->
      if !chunk?.length
        return
      ids = _.pluck(chunk, uuidField)
      tables.normalized.listing()
      .select('rm_property_id')
      .where(data_source_id: subtask.task_name)
      .whereIn('data_source_uuid', ids)
      .whereNotNull('deleted')
      .then (undeleteIds=[]) ->
        markPromise = tables.normalized.listing()
        .where(data_source_id: subtask.task_name)
        .whereIn('data_source_uuid', ids)
        .update(up_to_date: new Date(subtask.data.startTime), batch_id: subtask.batch_id, deleted: null)
        if undeleteIds.length == 0
          undeletePromise = Promise.resolve()
        else
          undeleteIds = _.pluck(undeleteIds, 'rm_property_id')
          undeletePromise = jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: undeleteIds, maxPage: 2500, laterSubtaskName: "finalizeData"})
        Promise.join markPromise, undeletePromise, () ->  # no-op

    .then (count) ->
      logger.debug () -> "getDataChunks total: #{count}"
  .catch retsService.isTransientRetsError, (error) ->
    throw new SoftFail(error, "Transient RETS error; try again later")
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to make RETS data up-to-date')


module.exports = {
  loadUpdates
  buildRecord
  finalizeData
  storePhotos
  deleteOldPhoto
  markUpToDate
}
