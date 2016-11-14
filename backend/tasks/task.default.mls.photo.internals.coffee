Promise = require 'bluebird'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:mls:photo')
finePhotologger = logger.spawn('fine')
retsService = require '../services/service.rets'
_ = require 'lodash'
analyzeValue = require '../../common/utils/util.analyzeValue'
mlsConfigService = require '../services/service.mls_config'
dbs = require '../config/dbs'
mlsPhotoUtil = require '../utils/util.mls.photos'
sqlHelpers = require '../utils/util.sql.helpers'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
externalAccounts = require '../services/service.externalAccounts'
awsService = require '../services/service.aws'
config = require '../config/config'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
ensureErrorUtil = require '../utils/errors/util.ensureError'
NamedError = require '../utils/errors/util.error.named'
keystore = require '../services/service.keystore'
crypto = require("crypto")


_md5 = (data) ->
  crypto.createHash('md5')
  .update(data)
  .digest('hex')


_getCdnPhotoShard = (opts) -> Promise.try () ->
  {newFileName, row, shardsPromise} = onMissingArgsFail
    args: opts
    required: ['newFileName', 'row']

  # logger.debug shardsPromise
  shardsPromise ?= keystore.cache.getValuesMap('cdn_shards')

  shardsPromise
  .then (cdnShards) ->
    cdnShards = _.mapValues cdnShards
    mod = _md5(newFileName).charCodeAt(0) % 2

    shard = _.find cdnShards, (s) ->
      parseInt(s.id) == mod

    if !shard?.url?
      throw new Error('Shard must have a url')

    "#{shard.url}/api/photos/resize?data_source_id=#{row.data_source_id}&data_source_uuid=#{row.data_source_uuid}"


_hasSameUploadDate = (uploadDate1, uploadDate2, allowNull = false) ->
  if allowNull && !uploadDate1? && !uploadDate2?
    return true

  uploadDate1? && uploadDate2? &&
    (new Date(uploadDate1)).getTime() == (new Date(uploadDate2)).getTime()

###
  using upload see service.aws.putObject comments

  The short of it is that we do not know the size of the payload. EVEN if rets-client gives a size if it is invalid
  it causes too many problems. It is easier to forgoe worying about size and just upload blindly!
###
_uploadPhoto = ({photoRes, newFileName, payload, row}) ->
  ensureError = ensureErrorUtil.ensureErrorFactory (err) ->
    return new NamedError('S3UploadError', err)
  new Promise (resolve, reject) ->
    awsService.upload
      extAcctName: config.EXT_AWS_PHOTO_ACCOUNT
      Key: newFileName
      ContentType: payload.contentType
      Metadata:
        data_source_id: row.data_source_id
        data_source_uuid: row.data_source_uuid
        height: photoRes.height
        width: photoRes.width
    .then (upload) ->

      payload.data.once 'error', (error) ->

        reject(ensureError(error))

      upload.concurrentParts(5)
      upload.once 'uploaded', (details) ->
        logger.spawn(row.data_source_id).debug details
        resolve(details)

      upload.once 'error', (error) ->
        reject(ensureError(error))

      payload.data.pipe(upload)

    .catch (error) -> #missing catch
      reject(ensureError(error))


_updatePhoto = (subtask, opts) -> Promise.try () ->
  if !opts
    logger.spawn(subtask.task_name).debug 'GTFO: _updatePhoto'
    return

  {newFileName, imageId, row, objectData, transaction, table} = onMissingArgsFail
    args: opts
    required: ['newFileName', 'imageId', 'row', 'table']

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

    if objectData
      obj.objectData = objectData

    Promise.try ->
      _makeUpsertPhoto {
        row
        obj
        imageId
        transaction
        table
        newFileName
      }
    .catch (error) ->
      logger.spawn(subtask.task_name).error analyzeValue.getFullDetails(error)
      logger.spawn(subtask.task_name).debug 'Handling error by enqueuing photo to be deleted.'
      _enqueuePhotoToDelete(obj.key, subtask.batch_id, {transaction})

_makeUpsertPhoto = ({row, obj, imageId, transaction, table, newFileName}) ->

  _getCdnPhotoShard({
    newFileName
    row
  })
  .then (cdn_photo) ->

    query = sqlHelpers.upsert {
      idObj: row
      entityObj: {
        photos: "#{imageId}": obj
        cdn_photo
        photo_last_mod_time: obj.objectData?.uploadDate
        actual_photo_count: 1
      }
      conflictOverrideObj:
        photos: table.raw(
          'jsonb_set(??.photos, ?, ?, true)',
          [
            table.tableName
            "{#{imageId}}"
            obj
          ]
        )
        actual_photo_count: table.raw(
          '(select count(*) from (select jsonb_object_keys(??.photos) union select ?) photoKeys)',
          [
            table.tableName
            imageId
          ]
        )
      dbFn: table
      transaction
    }

    logger.debug query.toString()
    query


_enqueuePhotoToDelete = (key, batch_id, {transaction}) ->
  if key?
    query = sqlHelpers.upsert {
      idObj: {key}
      entityObj: {key, batch_id}
      conflictOverrideObj: {}
      dbFn: tables.deletes.photos
      transaction
    }
    logger.debug query.toString()
    query
  else
    Promise.resolve()


storePhotos = (subtask, idObj) -> Promise.try () ->
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug idObj

  mlsId = subtask.task_name.split('_')[0]
  successCtr = 0
  errorsCtr = 0
  skipsCtr = 0
  needsRetry = false
  errorDetails = null

  {data_source_uuid, photo_id} = idObj
  photoRow =
    data_source_id: mlsId
    data_source_uuid: data_source_uuid

  photoResult = {}

  mlsConfigPromise = mlsConfigService.getByIdCached(mlsId)
  photoRowPromise = tables.finalized.photo()
  .where(photoRow)
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
      }
      .then (obj) -> new Promise (resolve, reject) ->

        finePhotologger.debug () -> "RETS responded:\n#{Object.keys(obj)}"

        promises = []
        mlsPhotoUtil.imagesHandle obj, (err, payload, isEnd) ->
          try
            finePhotologger.debug () -> "imagesHandle:\n#{payload}"

            if err
              finePhotologger.debug () -> "imagesHandle error:\n#{analyzeValue.getFullDetails(err)}"
              return reject(err)
            if isEnd
              finePhotologger.debug () -> "imagesHandle End!"
              return resolve(Promise.all promises)

            finePhotologger.debug _.omit(payload, 'data')
            {imageId, objectData} = payload

            if row? && _hasSameUploadDate(objectData?.uploadDate, row?.photos[imageId]?.objectData?.uploadDate)
              skipsCtr++
              finePhotologger.debug () -> "photo has same updateDate (#{objectData?.uploadDate}) GTFO."
              return

            # Deterministic but partition-friendly bucket names (10000 prefixes)
            # http://docs.aws.amazon.com/AmazonS3/latest/dev/request-rate-perf-considerations.html
            uploadDate = (new Date(objectData?.uploadDate || null)).getTime()
            partition = "#{mlsId}/#{data_source_uuid}/#{uploadDate}"
            partition = crypto.createHash('md5').update(partition).digest('hex').slice(0,4)
            newFileName = "#{partition}/#{mlsId}/#{data_source_uuid}/#{payload.name}"

            uploadPromise = _updatePhoto(subtask, {
              newFileName
              imageId
              data_source_uuid
              objectData
              row: photoRow
              transaction
              table: tables.finalized.photo
            })
            .then () ->
              if row?
                # Queue the OLD photo for deletion
                uploadDate = (new Date(row?.photos[imageId]?.objectData?.uploadDate || null)).getTime()
                partition = "#{mlsId}/#{data_source_uuid}/#{uploadDate}"
                partition = crypto.createHash('md5').update(partition).digest('hex').slice(0,4)
                oldFileName = "#{partition}/#{mlsId}/#{data_source_uuid}/#{payload.name}"
                _enqueuePhotoToDelete(oldFileName, subtask.batch_id, {transaction})
            .then () ->
              _uploadPhoto({photoRes, newFileName, payload, row: photoRow})
            .then () ->
              finePhotologger.debug 'photo upload success'
              successCtr++
              # Cancel any pending deletes since the photo uploaded successfully
              tables.deletes.photos({transaction}).delete({key: newFileName}).returning('key')
              .then (result) ->
                finePhotologger.debug result
            .catch (error) ->
              errorDetails ?= analyzeValue.getFullDetails(error)
              taskLogger.debug () -> "single-photo error (was: #{row?.photos[imageId]?.key}, now: #{newFileName}): #{errorDetails}"
              errorsCtr++
            promises.push(uploadPromise)
          catch err
            taskLogger.debug analyzeValue.getFullDetails(err)
            throw err
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
  .then () ->
    taskLogger.debug () -> "Photos uploaded: #{successCtr} | skipped: #{skipsCtr} | errors: #{errorsCtr}"
    if needsRetry || (errorsCtr > 0)
      sqlHelpers.upsert
        dbFn: tables.deletes.retry_photos
        idObj:
          data_source_id: mlsId
          data_source_uuid: data_source_uuid
          batch_id: subtask.batch_id
        entityObj:
          photo_id: photo_id
          error: errorDetails
        conflictOverrideObj:
          error: undefined
          photo_id: undefined
  .then () ->
    {successCtr, skipsCtr, errorsCtr}


module.exports = {
  storePhotos
}
