_ = require 'lodash'
Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
dbs = require '../config/dbs'
logger = require('../config/logger').spawn('task:mls')
finePhotologger = logger.spawn('photos.fine')
fineFinalizelogger = logger.spawn('finalize.fine')
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
retsService = require '../services/service.rets'
dataLoadHelpers = require './util.dataLoadHelpers'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
awsService = require '../services/service.aws'
mlsPhotoUtil = require '../utils/util.mls.photos'
uuid = require '../utils/util.uuid'
config = require '../config/config'
internals = require './util.mlsHelpers.internals'
analyzeValue = require '../../common/utils/util.analyzeValue'
jobQueue = require '../services/service.jobQueue'
mlsConfigService = require '../services/service.mls_config'
crypto = require 'crypto'

# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options={}) ->
  # figure out when we last got updates from this table
  updateThresholdPromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
  uuidPromise = internals.getUuidField(subtask.task_name)
  Promise.join updateThresholdPromise, uuidPromise, (updateThreshold, uuidField) ->
    retsService.getDataStream(subtask.task_name, minDate: updateThreshold, uuidField: uuidField, searchOptions: {limit: options.limit})
    .catch retsService.isMaybeTransientRetsError, (error) ->
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


_finalizeEntry = ({entries, subtask}) -> Promise.try ->
  index = 0
  for entry,i in entries
    if entry.status != 'discontinued'
      index = i
      break
  mainEntry = _.clone(entries[index])
  delete entries[index].shared_groups
  delete entries[index].subscriber_groups
  delete entries[index].hidden_fields
  delete entries[index].ungrouped_fields

  mainEntry.active = false
  delete mainEntry.deleted
  delete mainEntry.hide_address
  delete mainEntry.hide_listing
  delete mainEntry.rm_inserted_time
  delete mainEntry.rm_modified_time
  # eventually, we should probably remove those columns and set them in config_mls instead
  delete mainEntry.photo_last_mod_time
  delete mainEntry.photo_id

  mainEntry.prior_entries = sqlHelpers.safeJsonArray(entries)
  mainEntry.address = sqlHelpers.safeJsonArray(mainEntry.address)
  mainEntry.owner_address = sqlHelpers.safeJsonArray(mainEntry.owner_address)
  mainEntry.change_history = sqlHelpers.safeJsonArray(mainEntry.change_history)
  mainEntry.update_source = subtask.task_name

  mainEntry.baths_total = mainEntry.baths?.filter

  mainEntry


finalizeData = ({subtask, id, data_source_id, finalizedParcel, transaction, delay}) ->
  delay ?= subtask.data?.delay || 100
  parcelHelpers = require './util.parcelHelpers'#delayed require due to circular dependency

  listingsPromise = tables.normalized.listing()
  .select('*')
  .where
    rm_property_id: id
    hide_listing: false
    data_source_id: subtask.task_name
  .whereNull('deleted')
  .orderBy('rm_property_id')
  .orderBy('hide_listing')
  .orderBy('data_source_id')
  .orderBy('deleted')
  .orderByRaw('close_date DESC NULLS FIRST')

  parcelPromise = if finalizedParcel?
    Promise.resolve([finalizedParcel])
  else
    parcelHelpers.getParcelsPromise {rm_property_id: id, transaction}

  Promise.join listingsPromise, parcelPromise, (listings=[], parcel=[]) ->

    if listings.length == 0
      # might happen if a singleton listing is changed to hidden during the day
      return dataLoadHelpers.markForDelete(id, subtask.task_name, subtask.batch_id, {transaction})

    _finalizeEntry({entries: listings, subtask})
    .then (listing) ->
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


storePhotos = (subtask, data_source_uuid) -> Promise.try () ->
  successCtr = 0
  errorsCtr = 0
  skipsCtr = 0
  needsRetry = false
  errorDetails = null
  listingRow =
    data_source_id: subtask.task_name
    data_source_uuid: data_source_uuid

  mlsConfigPromise = mlsConfigService.getByIdCached(subtask.task_name)
  listingRowPromise = tables.normalized.listing()
  .where(listingRow)
  Promise.join mlsConfigPromise, listingRowPromise, (mlsConfig, rows) ->

    if !rows.length
      finePhotologger.debug 'No rows GTFO'
      return Promise.resolve()

    [row] = rows
    finePhotologger.debug "id: data_source_id: #{subtask.task_name} data_source_uuid: #{data_source_uuid}"

    #if the photo set is not updated GTFO
    logger = logger.spawn(subtask.task_name)
    logger.debug row.photo_last_mod_time

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
    .then (obj) -> new Promise (resolve, reject) ->
      promises = []
      mlsPhotoUtil.imagesHandle obj, (err, payload, isEnd) ->

        if err
          return reject err

        if isEnd
          return resolve(Promise.all promises)

        #file naming consideratons
        #http://docs.aws.amazon.com/AmazonS3/latest/dev/request-rate-perf-considerations.html
        newFileName = "#{uuid.genUUID()}/#{subtask.task_name}/#{data_source_uuid}/#{payload.name}"
        {imageId, objectData} = payload

        logger.debug _.omit payload, 'data'

        if mlsPhotoUtil.hasSameUploadDate(objectData?.uploadDate, row.photos[imageId]?.objectData?.uploadDate)
          skipsCtr++
          finePhotologger.debug 'photo has same updateDate GTFO.'
          return

        uploadPromise = dbs.transaction 'normalized', (transaction1) ->
          internals.updatePhoto(subtask, {newFileName, imageId, photo_id, objectData, row: listingRow, transaction: transaction1, table: tables.normalized.listing})
          .then () ->
            dbs.transaction 'main', (transaction2) ->
              internals.enqueuePhotoToDelete(row.photos[imageId]?.key, subtask.batch_id, transaction: transaction2)
              .then () ->
                internals.uploadPhoto({photoRes, newFileName, payload, row})
        .then () ->
          logger.debug 'photo upload success'
          successCtr++
        .catch (error) ->
          errorDetails ?= analyzeValue.getSimpleDetails(error)
          logger.debug () -> "single-photo error (was: #{row.photos[imageId]?.key}, now: #{newFileName}): #{errorDetails}"
          errorsCtr++
        promises.push(uploadPromise)
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.QuietlyHandledError(error, "problem storing photos for #{subtask.task_name}/#{data_source_uuid}")
  .catch (error) ->
    errorDetails ?= analyzeValue.getSimpleDetails(error)
    needsRetry = true
    logger.debug () -> "overall error: #{errorDetails}"
  .then () ->
    logger.debug "Uploaded #{successCtr} photos to aws bucket."
    logger.debug "Skipped #{skipsCtr} photos to aws bucket."
    logger.debug "Failed to upload #{errorsCtr} photos to aws bucket."
    if needsRetry || (errorsCtr > 0)
      sqlHelpers.upsert
        dbFn: tables.deletes.retry_photos
        idObj:
          data_source_id: subtask.task_name
          data_source_uuid: data_source_uuid
          batch_id: subtask.batch_id
        entityObj:
          error: errorDetails
        conflictOverrideObj:
          error: undefined

storePhotosNew = (subtask, idObj) -> Promise.try () ->
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug idObj

  mlsName = subtask.task_name.replace('_photos', '')
  successCtr = 0
  errorsCtr = 0
  skipsCtr = 0
  needsRetry = false
  errorDetails = null

  {data_source_uuid, photo_id} = idObj
  photoRow =
    data_source_id: mlsName
    data_source_uuid: data_source_uuid

  photoResult = {}

  mlsConfigPromise = mlsConfigService.getByIdCached(mlsName)
  photoRowPromise = tables.finalized.photo()
  .where(photoRow)
  Promise.join mlsConfigPromise, photoRowPromise, (mlsConfig, rows) ->

    # finePhotologger.debug photoRow

    taskLogger.debug "Found #{rows.length} existing photo rows for uuid #{data_source_uuid}"
    [row] = rows

    photoIds = {}

    #get all photos for a specific property
    photoIds["#{photo_id}"] = '*'

    # finePhotologger.debug photoIds

    photoType = mlsConfig.listing_data.largestPhotoObject
    {photoRes} = mlsConfig.listing_data

    dbs.transaction 'main', (transaction) ->

      retsService.getPhotosObject {
        mlsId: mlsName
        databaseName: 'Property'
        photoIds
        photoType
      }
      .then (obj) -> new Promise (resolve, reject) ->

        finePhotologger.debug "RETS responded:\n#{Object.keys(obj)}"

        promises = []
        mlsPhotoUtil.imagesHandle obj, (err, payload, isEnd) ->
          try
            finePhotologger.debug "imagesHandle:\n#{payload}"

            if err
              finePhotologger.debug "imagesHandle error:\n#{analyzeValue.getSimpleDetails(err)}"
              return reject err
            if isEnd
              finePhotologger.debug "imagesHandle End!"
              return resolve(Promise.all promises)

            finePhotologger.debug _.omit payload, 'data'
            {imageId, objectData} = payload

            if row? && mlsPhotoUtil.hasSameUploadDate(objectData?.uploadDate, row?.photos[imageId]?.objectData?.uploadDate)
              skipsCtr++
              finePhotologger.debug "photo has same updateDate (#{objectData?.uploadDate}) GTFO."
              return

            # Deterministic but partition-friendly bucket names (10000 prefixes)
            # http://docs.aws.amazon.com/AmazonS3/latest/dev/request-rate-perf-considerations.html
            uploadDate = (new Date(objectData?.uploadDate || null)).getTime()
            partition = "#{mlsName}/#{data_source_uuid}/#{uploadDate}"
            partition = crypto.createHash('md5').update(partition).digest('hex').slice(0,4)
            newFileName = "#{partition}/#{mlsName}/#{data_source_uuid}/#{payload.name}"

            uploadPromise = internals.updatePhoto(subtask, {
              newFileName
              imageId
              data_source_uuid
              objectData
              row: photoRow
              transaction
              table: tables.finalized.photo
              upsert: true
            })
            .then () ->
              if row?
                # Queue the OLD photo for deletion
                uploadDate = (new Date(row?.photos[imageId]?.objectData?.uploadDate || null)).getTime()
                partition = "#{mlsName}/#{data_source_uuid}/#{uploadDate}"
                partition = crypto.createHash('md5').update(partition).digest('hex').slice(0,4)
                oldFileName = "#{partition}/#{mlsName}/#{data_source_uuid}/#{payload.name}"
                internals.enqueuePhotoToDelete(oldFileName, subtask.batch_id, {transaction})
            .then () ->
              internals.uploadPhoto({photoRes, newFileName, payload, row: photoRow})
            .then () ->
              finePhotologger.debug 'photo upload success'
              successCtr++
              # Cancel any pending deletes since the photo uploaded successfully
              tables.deletes.photos({transaction}).delete({key: newFileName}).returning('key')
              .then (result) ->
                finePhotologger.debug result
            .catch (error) ->
              errorDetails ?= analyzeValue.getSimpleDetails(error)
              taskLogger.debug () -> "single-photo error (was: #{row?.photos[imageId]?.key}, now: #{newFileName}): #{errorDetails}"
              errorsCtr++
            promises.push(uploadPromise)
          catch err
            taskLogger.debug analyzeValue.getSimpleDetails(err)
            throw err
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.QuietlyHandledError(error, "problem storing photos for #{mlsName}/#{data_source_uuid}")
  .catch (error) ->
    errorDetails ?= analyzeValue.getSimpleDetails(error)
    if errorDetails.indexOf("20403 (NO_OBJECT_FOUND)") == -1
      needsRetry = true
    taskLogger.debug () -> "overall error: #{errorDetails}"
  .then () ->
    taskLogger.debug "Photos uploaded: #{successCtr} | skipped: #{skipsCtr} | errors: #{errorsCtr}"
    if needsRetry || (errorsCtr > 0)
      sqlHelpers.upsert
        dbFn: tables.deletes.retry_photos
        idObj:
          data_source_id: mlsName
          data_source_uuid: data_source_uuid
          batch_id: subtask.batch_id
        entityObj:
          error: errorDetails
        conflictOverrideObj:
          error: undefined
  .then () ->
    {successCtr, skipsCtr, errorsCtr}

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
  .catch retsService.isMaybeTransientRetsError, (error) ->
    throw new SoftFail(error, "Transient RETS error; try again later")
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to make RETS data up-to-date')


getMlsField = (mlsId, fieldName) ->
  internals.getMlsField(mlsId, fieldName)

module.exports = {
  loadUpdates
  buildRecord
  finalizeData
  storePhotos
  storePhotosNew
  deleteOldPhoto
  markUpToDate
  getMlsField
}
