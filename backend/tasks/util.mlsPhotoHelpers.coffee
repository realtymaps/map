Promise =  require 'bluebird'
through = require 'through2'
_ = require 'lodash'
logger = require('../config/logger').spawn('task:util:mls:photo')
fineLogger = require('../config/logger').spawn('task:util:mls:photo:fine')
require '../extensions/stream'
externalAccounts = require '../services/service.externalAccounts'
awsService = require '../services/service.aws'
config = require '../config/config'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
ensureErrorUtil = require '../utils/errors/util.ensureError'
NamedError = require '../utils/errors/util.error.named'
keystore = require '../services/service.keystore'
cryptoUtil = require '../utils/util.crypto'
analyzeValue = require '../../common/utils/util.analyzeValue'
sqlHelpers = require '../utils/util.sql.helpers'
tables = require '../config/tables'


getCdnPhotoShard = (opts) -> Promise.try () ->
  {newFileName, row, shardsPromise} = onMissingArgsFail
    args: opts
    required: ['newFileName', 'row']

  # logger.debug shardsPromise
  shardsPromise ?= keystore.cache.getValuesMap('cdn_shards')

  shardsPromise
  .then (cdnShards) ->
    cdnShards = _.mapValues cdnShards
    mod = cryptoUtil.md5(newFileName).charCodeAt(0) % 2

    shard = _.find cdnShards, (s) ->
      parseInt(s.id) == mod

    if !shard?.url?
      throw new Error('Shard must have a url')

    "#{shard.url}/api/photos/resize?data_source_id=#{row.data_source_id}&data_source_uuid=#{row.data_source_uuid}"


hasSameUploadDate = (uploadDate1, uploadDate2, allowNull = false) ->
  if allowNull && !uploadDate1? && !uploadDate2?
    return true

  uploadDate1? && uploadDate2? &&
    (new Date(uploadDate1)).getTime() == (new Date(uploadDate2)).getTime()

###
  using upload see service.aws.putObject comments

  The short of it is that we do not know the size of the event. EVEN if rets-client gives a size if it is invalid
  it causes too many problems. It is easier to forgoe worying about size and just upload blindly!
###
uploadPhoto = ({photoRes, newFileName, event, row}) ->
  ensureError = ensureErrorUtil.ensureErrorFactory (err) ->
    return new NamedError('S3UploadError', err)
  new Promise (resolve, reject) ->
    awsService.upload
      extAcctName: config.EXT_AWS_PHOTO_ACCOUNT
      Key: newFileName
      ContentType: event.headerInfo.contentType
      Metadata:
        data_source_id: row.data_source_id
        data_source_uuid: row.data_source_uuid
        height: photoRes.height
        width: photoRes.width
    .then (upload) ->

      upload.concurrentParts(5)

      sources = {upload, "event.dataStream": event.dataStream}
      registerEventHandler = (name, source, extraHandler) ->
        sources[source].once name, (event) ->
          logger.spawn(row.data_source_id).debug () -> "[#{newFileName}] '#{name}' event (#{source}): #{analyzeValue.getSimpleMessage(event)}"
          extraHandler?(event)

      registerEventHandler 'uploaded', 'upload', (details) ->
        resolve(details)
      registerEventHandler 'error', 'upload', (error) ->
        reject(ensureError(error))
      registerEventHandler 'error', 'event.dataStream', (error) ->
        reject(ensureError(error))
      ###
      # the additional handlers below are just for troubleshooting, uncomment as necessary
      registerEventHandler('close', 'upload')
      registerEventHandler('end', 'upload')
      registerEventHandler('finish', 'upload')
      registerEventHandler('close', 'event.dataStream')
      registerEventHandler('end', 'event.dataStream')
      registerEventHandler('finish', 'event.dataStream')
      ###


      event.dataStream
      .pipe(upload)

    .catch (error) -> #missing catch
      logger.spawn(row.data_source_id).debug () -> "[#{newFileName}] caught error: #{analyzeValue.getSimpleMessage(error)}"
      reject(ensureError(error))


updatePhoto = (subtask, opts) -> Promise.try () ->
  l = logger.spawn(subtask.task_name)
  if !opts
    l.debug 'GTFO: updatePhoto'
    return

  {newFileName, imageId, row, objectData, transaction, location, photo_id} = onMissingArgsFail
    args: opts
    required: ['newFileName', 'imageId', 'row', 'photo_id']

  meta =
    key: newFileName
    url: null

  if objectData
    meta.objectData = objectData

  metaPromise = if location #cached woot
    l.debug -> 'cached'
    meta.url = location
    Promise.resolve(meta)
  else
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
      meta.url = "#{config.S3_URL}/#{s3Info.other.bucket}/#{newFileName}"
      meta

  metaPromise
  .then () ->
    Promise.try ->
      makeUpsertPhoto {
        row
        meta
        imageId
        transaction
        newFileName
        photo_id
      }
    .catch (error) ->
      l.error(analyzeValue.getFullDetails(error))

      if !location? #we have a bad image cached on S3, clean it up later
        l.debug -> 'Handling error by enqueuing photo to be deleted.'
        enqueuePhotoToDelete(meta.key, subtask.batch_id, {transaction})

makeUpsertPhoto = ({row, meta, imageId, transaction, newFileName, photo_id}) ->
  table = tables.finalized.photo

  getCdnPhotoShard({
    newFileName
    row
  })
  .then (cdn_photo) ->

    sqlHelpers.upsert {
      idObj: row
      entityObj: {
        photos: "#{imageId}": meta
        cdn_photo
        photo_last_mod_time: meta.objectData?.uploadDate
        actual_photo_count: 1
        photo_id
      }
      conflictOverrideObj:
        photos: table.raw(
          'jsonb_set(??.photos, ?, ?, true)',
          [
            table.tableName
            "{#{imageId}}"
            meta
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


enqueuePhotoToDelete = (key, batch_id, {transaction}) ->
  if key?
    sqlHelpers.upsert {
      idObj: {key}
      entityObj: {key, batch_id}
      conflictOverrideObj: {}
      dbFn: tables.deletes.photos
      transaction
    }
  else
    Promise.resolve()


storeStream = ({photoRowClause, row, transaction, photoRes, subtask, mlsId, data_source_uuid, photo_id} = {}) ->
  taskLogger = logger.spawn(subtask.task_name)

  successCtr = 0
  uploadsCtr = 0
  errorsCtr = 0
  skipsCtr = 0
  errorDetails = null

  flush = (cb) ->
    fineLogger.debug -> "storeStream End!"

    @emit 'counters', {successCtr, skipsCtr, errorsCtr, uploadsCtr, errorDetails}
    cb()

  # coffeelint: disable=check_scope
  transform = (event, enc, cb) ->
  # coffeelint: enable=check_scope
    try
      fineLogger.debug -> "storeStream event (#{event.headerInfo.objectId})"
      {imageId} = event.extra
      {objectData, location} = event.headerInfo

      if row? && hasSameUploadDate(objectData?.uploadDate, row?.photos[imageId]?.objectData?.uploadDate)
        skipsCtr++
        fineLogger.debug () -> "photo has same updateDate (#{objectData?.uploadDate}) GTFO."
        cb()
        return

      # Deterministic but partition-friendly bucket names (10000 prefixes)
      # http://docs.aws.amazon.com/AmazonS3/latest/dev/request-rate-perf-considerations.html
      uploadDate = (new Date(objectData?.uploadDate || null)).getTime()
      partition = "#{mlsId}/#{data_source_uuid}/#{uploadDate}"
      partition = cryptoUtil.md5(partition).slice(0,4)
      newFileName = "#{partition}/#{mlsId}/#{data_source_uuid}/#{event.extra.fileName}"

      Promise.try () ->
        if location? #don't cache it or worry about deleting it; it is already cached
          fineLogger.debug -> "has location, GTFO"
          return
        uploadPhoto({photoRes, newFileName, event, row: photoRowClause})
        .then () ->
          fineLogger.debug -> "upload successful"
          uploadsCtr++
          # Cancel any pending deletes since the photo uploaded successfully
          tables.deletes.photos({transaction}).delete({key: newFileName}).returning('key')
      .then () ->
        updatePhoto(subtask, {
          newFileName
          imageId
          data_source_uuid
          objectData
          row: photoRowClause
          transaction
          location
          photo_id
        })
      .then () ->
        if row? && !location?
          # Queue the OLD photo for deletion
          uploadDate = (new Date(row?.photos[imageId]?.objectData?.uploadDate || null)).getTime()
          partition = "#{mlsId}/#{data_source_uuid}/#{uploadDate}"
          partition = cryptoUtil.md5(partition).slice(0,4)
          oldFileName = "#{partition}/#{mlsId}/#{data_source_uuid}/#{event.extra.fileName}"
          enqueuePhotoToDelete(oldFileName, subtask.batch_id, {transaction})
      .then () ->
        successCtr++
      .catch (error) ->
        errorDetails ?= analyzeValue.getFullDetails(error)
        logger.error(errorDetails)
        taskLogger.debug () -> "single-photo error (was: #{row?.photos[imageId]?.key}, now: #{newFileName}): #{errorDetails}"
        errorsCtr++

      .then () ->
        cb()
      .catch (error) ->
        taskLogger.debug -> "promise error while processing event: #{JSON.stringify(event.headerInfo)}\n#{analyzeValue.getFullDetails(err)}"
        cb(error)

    catch err
      taskLogger.debug -> "synchronous error while processing event: #{JSON.stringify(event.headerInfo)}\n#{analyzeValue.getFullDetails(err)}"
      cb(err)

  return through.obj(transform, flush)


module.exports = {
  getCdnPhotoShard
  hasSameUploadDate
  uploadPhoto
  updatePhoto

  enqueuePhotoToDelete
  makeUpsertPhoto

  storeStream
}
