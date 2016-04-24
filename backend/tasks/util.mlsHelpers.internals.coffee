tables = require '../config/tables'
logger = require('../config/logger').spawn('util.mlsHelpers.internals')

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


module.exports = {
  makeInsertPhoto
}
