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

makeInsertPhoto = ({listingRow, cdnPhotoStr, jsonObjStr, imageId, doReturnStr, transaction}) ->
  doReturnStr ?= false

  updatedInfo =
    photo_import_error: null
    photos: tables.normalized.listing.raw("jsonb_set(photos, '{#{imageId}}', ?, true)", jsonObjStr)
  if cdnPhotoStr
    updatedInfo.cdn_photo = cdnPhotoStr

  query = tables.normalized.listing({transaction})
  .where(listingRow)
  .update(updatedInfo)

  if doReturnStr
    return query.toString()
  query


###
# this function works backwards from the validation for data_source_uuid to determine the LongName and then the SystemName
# of the UUID field
# TODO: change this to use the KeyField metadata from RETS
###
getUuidField = (mlsId) ->
  mlsConfigService.getByIdCached(mlsId)
  .then (mlsInfo) ->
    columnDataPromise = retsCacheService.getColumnList(mlsId: mlsId, databaseId: mlsInfo.listing_data.db, tableId: mlsInfo.listing_data.table)
    validationInfoPromise = dataLoadHelpers.getValidationInfo('mls', mlsId, 'listing', 'base', 'data_source_uuid')
    Promise.join columnDataPromise, validationInfoPromise, (columnData, validationInfo) ->
      for field in columnData
        if field.LongName == validationInfo.validationMap.base[0].input
          uuidField = field.SystemName
          break
      if !uuidField
        throw new Error("can't locate uuidField for #{mlsId} (SystemName for #{validationInfo.validationMap.base[0].input})")
      return uuidField

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

enqueuePhotoToDelete = (key, batch_id, {transaction}) ->
  if key?
    tables.deletes.photos({transaction})
    .insert {key, batch_id}
  else
    Promise.resolve()

updatePhoto = (subtask, opts) -> Promise.try () ->
  if !opts
    logger.spawn(subtask.task_name).debug 'GTFO: _updatePhoto'
    return

  {newFileName, imageId, photo_id, listingRow, objectData, transaction} = onMissingArgsFail
    args: opts
    required: ['newFileName', 'imageId', 'photo_id', 'listingRow']

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

    makeInsertPhoto {
      listingRow
      jsonObjStr
      imageId
      photo_id
      transaction
    }
    .catch (error) ->
      logger.spawn(subtask.task_name).error error
      logger.spawn(subtask.task_name).debug 'Handling error by enqueuing photo to be deleted.'
      enqueuePhotoToDelete(obj.key, subtask.batch_id, {transaction})

module.exports = {
  uploadPhoto
  enqueuePhotoToDelete
  updatePhoto
  makeInsertPhoto
  getUuidField
}
