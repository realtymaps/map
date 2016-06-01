_ = require 'lodash'
Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
dbs = require '../config/dbs'
logger = require('../config/logger').spawn('util.mlsHelpers')
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


ONE_YEAR_MILLIS = 365*24*60*60*1000


# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options) ->
  # figure out when we last got updates from this table
  dataLoadHelpers.getUpdateThreshold({subtask, fullRefreshMillis: ONE_YEAR_MILLIS})
  .then (updateThreshold) ->
    tables.config.mls()
    .where(id: subtask.task_name)
    .then (mlsInfo) ->
      mlsInfo = mlsInfo?[0]
      retsService.getDataStream(mlsInfo, options?.limit, updateThreshold)
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
    .then (numRawRows) ->
      result = {numRawRows}
      if updateThreshold == 0
        result.deletes = dataLoadHelpers.DELETE.UNTOUCHED
        result.setRefreshTimestamp = true
      else
        result.deletes = dataLoadHelpers.DELETE.NONE
      return result
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


finalizeData = ({subtask, id, data_source_id, activeParcel}) ->
  parcelHelpers = require './util.parcelHelpers'#delayed require due to circular dependency

  listingsPromise = tables.property.listing()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .where(hide_listing: false)
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderBy('hide_listing')
  .orderByRaw('close_date DESC NULLS FIRST')



  Promise.join listingsPromise
  , parcelHelpers.getParcelsPromise(rm_property_id: id, active: activeParcel)
  , (listings=[], parcel=[]) ->
    if listings.length == 0
      # might happen if a singleton listing is deleted during the day
      return tables.deletes.property()
      .insert
        rm_property_id: id
        data_source_id: subtask.task_name
        batch_id: subtask.batch_id

    listing = dataLoadHelpers.finalizeEntry(listings)
    listing.data_source_type = 'mls'
    _.extend(listing, parcel[0])
    Promise.delay(100)  #throttle for heroku's sake
    .then () ->
      # do owner name and zoning promotion logic
      if listing.owner_name? || listing.owner_name_2? || listing.zoning
        # keep previously-promoted values
        return
      if listing.fips_code != '12021'
        return
      # need to query the tax table to get values to promote
      tables.property.tax(subid: listing.fips_code)
      .select('promoted_values')
      .where
        rm_property_id: id
      .then (results=[]) ->
        if results[0]?.promoted_values
          # promote values into this listing
          listing.extend(results[0].promoted_values)
          # save back to the listing table to avoid making checks in the future
          tables.property.listing()
          .where
            data_source_id: listing.data_source_id
            data_source_uuid: listing.data_source_uuid
          .update(results[0].promoted_values)
    .then () ->
      dbs.get('main').transaction (transaction) ->
        tables.property.combined(transaction: transaction)
        .where
          rm_property_id: id
          data_source_id: data_source_id || subtask.task_name
          active: false
        .delete()
        .then () ->
          tables.property.combined(transaction: transaction)
          .insert(listing)

_getPhotoSettings = (subtask, listingRow) -> Promise.try () ->
  mlsConfigQuery = tables.config.mls()
  .where(id: subtask.task_name)
  .then (results) ->
    sqlHelpers.expectSingleRow(results)

  query = tables.property.listing().where listingRow

  Promise.all [mlsConfigQuery, query]

_updatePhoto = (subtask, opts) -> Promise.try () ->
  if !opts
    logger.debug 'GTFO: _updatePhoto'
    return

  onMissingArgsFail
    args: opts
    required: ['newFileName', 'imageId', 'photo_id', 'data_source_uuid']

  {newFileName, imageId, photo_id, data_source_uuid, objectData} = opts
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
      cdnPhotoStrPromise = mlsPhotoUtil.getCndPhotoShard(_.extend {}, opts, data_source_id: subtask.task_name)

    cdnPhotoStrPromise
    .then (cdnPhotoStr) ->

      internals.makeInsertPhoto {
        data_source_id: subtask.task_name
        data_source_uuid
        cdnPhotoStr
        jsonObjStr
        imageId
        photo_id
      }

    .catch (error) ->
      logger.error error
      logger.debug 'Handling error by enqueing photo to be deleted.'
      _enqueuePhotoToDelete obj.key, subtask.batch_id

_enqueuePhotoToDelete = (key, batch_id) ->
  if key?
    tables.deletes.photos()
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
        logger.debug details
        resolve(details)

      upload.once 'error', (error) ->
        reject error

      payload.data.pipe(upload)

    .catch (error) -> #missing catch
      reject error

storePhotos = (subtask, listingRow) -> Promise.try () ->
  finePhotologger.debug subtask.task_name
  finePhotologger.debug listingRow, true

  _getPhotoSettings(subtask, listingRow)
  .then ([mlsConfig, rows]) ->

    if !rows.length
      finePhotologger.debug 'No rows GTFO'
      return Promise.resolve()

    [row] = rows
    finePhotologger.debug "id: data_source_id: #{listingRow.data_source_id} data_source_uuid: #{listingRow.data_source_uuid}"

    #if the photo set is not updated GTFO
    logger.debug row.photo_last_mod_time

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
      serverInfo: mlsConfig
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
            logger.debug 'ERROR: rets-client getObjects!!!!!!!!!!!!!'
            return reject err

          if isEnd
            return resolve(
              Promise.all promises
              .then (args...) ->
                logger.debug "Uploaded #{successCtr} photos to aws bucket."
                logger.debug "Skipped #{skipsCtr} photos to aws bucket."
                logger.debug "Failed to upload #{errorsCtr} photos to aws bucket."
                args
            )

          #file naming consideratons
          #http://docs.aws.amazon.com/AmazonS3/latest/dev/request-rate-perf-considerations.html
          newFileName = "#{uuid.genUUID()}/#{subtask.task_name}/#{payload.name}"
          {imageId, objectData} = payload

          logger.debug _.omit payload, 'data'

          if mlsPhotoUtil.hasSameUploadDate(objectData?.uploadDate, row.photos[imageId]?.objectData?.uploadDate)
            skipsCtr++
            finePhotologger.debug 'photo has same updateDate GTFO.'
            return promises.push Promise.resolve(null)

          promises.push(
            _uploadPhoto({photoRes, newFileName, payload, row})
            .then () ->
              _enqueuePhotoToDelete row.photos[imageId]?.key, subtask.batch_id
            .then () ->
              logger.debug 'photo upload success'
              successCtr++

              tables.property.listing()
              .where(listingRow)
              .update(photo_import_error: null)
              .then () ->
                {newFileName, imageId, photo_id, objectData, data_source_uuid: listingRow.data_source_uuid}
            .catch (error) ->
              logger.debug 'ERROR: putObject!!!!!!!!!!!!!!!!'
              logger.debug analyzeValue.getSimpleDetails(error)
              #record the error and move on
              tables.property.listing()
              .where(listingRow)
              .update(photo_import_error: analyzeValue.getSimpleDetails(error))
              .then () ->
                null
          )

      savesPromise.then ([saves]) ->
        #filter/flatMap (remove nulls / GTFOS)
        Promise.all _.filter(saves).map _updatePhoto.bind(null, subtask)

    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'problem storing photo')
    .catch (error) ->
      tables.property.listing()
      .where(listingRow)
      .update photo_import_error: analyzeValue.getSimpleDetails(error)

deleteOldPhoto = (subtask, id) -> Promise.try () ->
  tables.deletes.photos()
  .where {id}
  .then (results) ->
    if !results?.length
      return

    [{id, key}] = results
    logger.debug "deleting: id: #{id}, key: #{key}"

    awsService.deleteObject
      extAcctName: config.EXT_AWS_PHOTO_ACCOUNT
      Key: key
    .then () ->
      logger.debug 'succesful deletion of aws photo ' + key

      tables.deletes.photos()
      .where {id}
      .del()
      .catch (error) ->
        throw new SoftFail(error, "Transient Photo Deletion error; try again later. Failed to delete from database.")
    .catch (error) ->
      throw new SoftFail(error, "Transient AWS Photo Deletion error; try again later")


module.exports = {
  loadUpdates
  buildRecord
  finalizeData
  storePhotos
  deleteOldPhoto
}
