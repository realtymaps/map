Promise = require 'bluebird'
tables = require '../config/tables'
logger = require('../config/logger').spawn('util.mlsHelpers.internals')
retsCacheService = require '../services/service.retsCache'
dataLoadHelpers = require './util.dataLoadHelpers'

makeInsertPhoto = ({data_source_id, data_source_uuid, cdnPhotoStr, jsonObjStr, imageId, photo_id, doReturnStr}) ->
  doReturnStr ?= false

  cdnPhotoQueryPartStr = ''
  if cdnPhotoStr
    cdnPhotoQueryPartStr = ',cdn_photo = :cdn_photo'

  query =
    tables.property.listing()
    .raw("""
      UPDATE listing set
      photos=jsonb_set(photos, '{#{imageId}}', :json_str, true)#{cdnPhotoQueryPartStr}
      WHERE
       data_source_id = :data_source_id AND
       data_source_uuid = :data_source_uuid AND
       photo_id = :photo_id;
    """, {
      json_str: jsonObjStr
      data_source_id
      data_source_uuid
      photo_id
      cdn_photo: cdnPhotoStr
    })

  if doReturnStr
    return query.toString()
  query

###
# this function works backwards from the validation for data_source_uuid to determine the LongName and then the SystemName
# of the UUID field
###
getUuidField = (mlsInfo) ->
  columnDataPromise = retsCacheService.getColumnList(mlsId: mlsInfo.id, databaseId: mlsInfo.listing_data.db, tableId: mlsInfo.listing_data.table)
  validationInfoPromise = dataLoadHelpers.getValidationInfo('mls', mlsInfo.id, 'listing', 'base', 'data_source_uuid')
  Promise.join columnDataPromise, validationInfoPromise, (columnData, validationInfo) ->
    for field in columnData
      if field.LongName == validationInfo.validationMap.base[0].input
        uuidField = field.SystemName
        break
    if !uuidField
      throw new Error("can't locate uuidField for #{mlsInfo.id} (SystemName for #{validationInfo.validationMap.base[0].input})")
    return uuidField


module.exports = {
  makeInsertPhoto
  getUuidField
}
