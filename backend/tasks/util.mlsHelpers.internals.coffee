Promise = require 'bluebird'
tables = require '../config/tables'
logger = require('../config/logger').spawn('util.mlsHelpers.internals')
retsCacheService = require '../services/service.retsCache'
dataLoadHelpers = require './util.dataLoadHelpers'
mlsConfigService = require '../services/service.mls_config'
awsService = require '../services/service.aws'
config = require '../config/config'
finePhotologger = logger.spawn('photos.fine.internals')
externalAccounts = require '../services/service.externalAccounts'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
analyzeValue = require '../../common/utils/util.analyzeValue'
ensureErrorUtil = require '../utils/errors/util.ensureError'
NamedError = require '../utils/errors/util.error.named'
_ = require 'lodash'
sqlHelpers = require '../utils/util.sql.helpers'
mlsPhotoUtil = require '../utils/util.mls.photos'

makeUpdatePhoto = ({row, cdnPhotoStr, jsonObjStr, imageId, doReturnStr, transaction, table}) ->
  doReturnStr ?= false

  finePhotologger.debug jsonObjStr

  updatedInfo =
    photos: table().raw("jsonb_set(photos, '{#{imageId}}', ?, true)", jsonObjStr)
  if cdnPhotoStr
    updatedInfo.cdn_photo = cdnPhotoStr

  query = table({transaction})
  .where(row)
  .update(updatedInfo)

  logger.debug query.toString()

  if doReturnStr
    logger.debug query.toString()
    return query.toString()
  query

makeUpsertPhoto = ({row, obj, imageId, transaction, table, newFileName}) ->

  mlsPhotoUtil.getCndPhotoShard({
    newFileName: newFileName
    listingRow: row
  })
  .then (cdnPhotoStr) ->

    query = table.raw("""
      INSERT INTO ?? ("data_source_id", "data_source_uuid", "photos", "cdn_photo", "photo_last_mod_time", "actual_photo_count")
      VALUES (
        ?,
        ?,
        ?,
        ?,
        ?,
        1
      )
      ON CONFLICT ("data_source_id", "data_source_uuid")
      DO UPDATE SET ("photos", "photo_last_mod_time", "actual_photo_count") = (
        jsonb_set(??.photos, '{#{imageId}}', ?, true),
        ?,
        (select count(*) from (select jsonb_object_keys(??.photos) union select ?) photoKeys)
      )
      RETURNING "data_source_id", "data_source_uuid"
      """,
      [
        table.tableName,
        row.data_source_id,
        row.data_source_uuid,
        JSON.stringify("#{imageId}": obj),
        cdnPhotoStr,
        obj.objectData?.uploadDate,
        table.tableName,
        JSON.stringify(obj),
        obj.objectData?.uploadDate,
        table.tableName,
        imageId
      ]
    )

    # logger.debug (query)
    query


###
# these function works backwards from the validation for `fieldName` (e.g. "data_source_uuid") to determine the LongName and then the
# SystemName of the UUID field
# TODO: change this to use the KeyField metadata from RETS
###

getMlsField = (mlsId, rmapsFieldName) ->
  mlsConfigService.getByIdCached(mlsId)
  .then (mlsInfo) ->
    columnDataPromise = retsCacheService.getColumnList(mlsId: mlsId, databaseId: mlsInfo.listing_data.db, tableId: mlsInfo.listing_data.table)
    validationInfoPromise = dataLoadHelpers.getValidationInfo('mls', mlsId, 'listing', 'base', rmapsFieldName)
    Promise.join columnDataPromise, validationInfoPromise, (columnData, validationInfo) ->
      for field in columnData
        if field.LongName == validationInfo.validationMap.base[0].input
          mlsFieldName = field.SystemName
          break
      if !mlsFieldName
        throw new Error("can't locate `#{mlsFieldName}` for #{mlsId} (SystemName for #{validationInfo.validationMap.base[0].input})")
      return mlsFieldName

getUuidField = (mlsId) -> # existed prior to `getMlsField` above; keeping it here
  getMlsField(mlsId, 'data_source_uuid')


# cdnPhotoStrPromise = Promise.resolve('')
# if imageId == 0
#   cdnPhotoStrPromise = mlsPhotoUtil.getCndPhotoShard(opts)
#
# cdnPhotoStrPromise
# .then (cdnPhotoStr) ->

###
  using upload see service.aws.putObject comments

  The short of it is that we do not know the size of the payload. EVEN if rets-client gives a size if it is invalid
  it causes too many problems. It is easier to forgoe worying about size and just upload blindly!
###
uploadPhoto = ({photoRes, newFileName, payload, row}) ->
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

enqueuePhotoToDelete = (key, batch_id, {transaction}) ->
  # TODO: this should be upsert
  if key?
    tables.deletes.photos({transaction})
    .insert {key, batch_id}
  else
    Promise.resolve()

updatePhoto = (subtask, opts) -> Promise.try () ->
  if !opts
    logger.spawn(subtask.task_name).debug 'GTFO: _updatePhoto'
    return

  {newFileName, imageId, row, objectData, transaction, table, upsert} = onMissingArgsFail
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
      if upsert
        makeUpsertPhoto {
          row
          obj
          imageId
          transaction
          table
          newFileName
        }
      else
        makeUpdatePhoto {
          row
          jsonObjStr: JSON.stringify(obj)
          imageId
          transaction
          table
        }

    .catch (error) ->
      logger.spawn(subtask.task_name).error analyzeValue.getSimpleDetails(error)
      logger.spawn(subtask.task_name).debug 'Handling error by enqueuing photo to be deleted.'
      enqueuePhotoToDelete(obj.key, subtask.batch_id, {transaction})

module.exports = {
  uploadPhoto
  enqueuePhotoToDelete
  updatePhoto
  makeUpdatePhoto
  getUuidField
  getMlsField
}
