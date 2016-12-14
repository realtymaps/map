Promise = require 'bluebird'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:mls:photo')
retsService = require '../services/service.rets'
analyzeValue = require '../../common/utils/util.analyzeValue'
mlsConfigService = require '../services/service.mls_config'
dbs = require '../config/dbs'
mlsPhotoUtil = require '../utils/util.mls.photos'
sqlHelpers = require '../utils/util.sql.helpers'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
photoHelpers = require './util.mlsPhotoHelpers'
require '../extensions/stream'


storePhotos = (subtask, idObj) -> Promise.try () ->
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug -> 'storePhotos: '+JSON.stringify(idObj)

  mlsId = subtask.task_name.split('_')[0]

  needsRetry = false
  errorDetails = null

  {data_source_uuid, photo_id} = idObj
  photoRowClause = {data_source_id: mlsId, data_source_uuid}

  mlsConfigPromise = mlsConfigService.getByIdCached(mlsId)
  photoRowPromise = tables.finalized.photo().where(photoRowClause)

  Promise.join mlsConfigPromise, photoRowPromise, (mlsConfig, rows) ->

    taskLogger.debug () -> "Found #{rows.length} existing photo rows for uuid #{data_source_uuid}"
    [row] = rows

    photoIds = {}

    # get all photos for a specific property
    photoIds["#{photo_id}"] = '*'

    photoType = mlsConfig.listing_data.largestPhotoObject
    {photoRes} = mlsConfig.listing_data

    dbs.transaction 'main', (transaction) ->

      retsService.getPhotosObject {
        mlsId: mlsId
        databaseName: mlsConfig.listing_data.db
        photoIds
        photoType
        objectsOpts:
          Location: mlsConfig.listing_data.Location || 0
      }
      .then (obj) ->

        mlsPhotoUtil.toPhotoStream(obj)
        .pipe(photoHelpers.storeStream({
          photoRowClause
          row
          transaction
          photoRes
          subtask
          mlsId
          data_source_uuid
          photo_id
        }))
        .toCounterPromise()

  .catch errorHandlingUtils.isUnhandled, (error) ->
    rootError = errorHandlingUtils.getRootCause(error)
    if (rootError instanceof retsService.RetsReplyError) && (rootError.replyTag == 'NO_RECORDS_FOUND')
      # assume the listing has been deleted / we no longer have access
      taskLogger.debug () -> "Listing no longer accessible, skipping: #{mlsId}/#{data_source_uuid}"
      return
    throw new errorHandlingUtils.QuietlyHandledError(error, "problem storing photos for #{mlsId}/#{data_source_uuid}")
  .catch (error) ->
    errorDetails ?= analyzeValue.getFullDetails(error)
    needsRetry = true
    taskLogger.debug () -> "overall error: #{errorDetails}"
  .then ({successCtr, skipsCtr, errorsCtr, uploadsCtr}) ->
    Promise.try () ->
      if !needsRetry && errorsCtr == 0
        return
      sqlHelpers.upsert
        dbFn: tables.deletes.retry_photos
        idObj: photoRowClause
        entityObj:
          batch_id: subtask.batch_id
          photo_id: photo_id
          error: errorDetails
        conflictOverrideObj:
          photo_id: undefined
          retries: tables.deletes.retry_photos.raw('EXCLUDED.retries + 1')
    .then () ->
      taskLogger.debug () -> "Photos uploaded: #{uploadsCtr} | skipped: #{skipsCtr} | errors: #{errorsCtr} | successes: #{successCtr}"
      return {successCtr, skipsCtr, errorsCtr, uploadsCtr}


module.exports = {
  storePhotos
}
