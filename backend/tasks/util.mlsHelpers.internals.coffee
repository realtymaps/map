Promise = require 'bluebird'
tables = require '../config/tables'
logger = require('../config/logger').spawn('util.mlsHelpers.internals')
retsCacheService = require '../services/service.retsCache'
dataLoadHelpers = require './util.dataLoadHelpers'
mlsConfigService = require '../services/service.mls_config'


makeInsertPhoto = ({listingRow, cdnPhotoStr, jsonObjStr, imageId, photo_id, doReturnStr}) ->
  doReturnStr ?= false

  updatedInfo =
    photo_import_error: null
    photos: tables.normalized.listing.raw("jsonb_set(photos, '{#{imageId}}', ?, true)", jsonObjStr)
  if cdnPhotoStr
    updatedInfo.cdn_photo = cdnPhotoStr

  query = tables.normalized.listing()
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


module.exports = {
  makeInsertPhoto
  getUuidField
}
