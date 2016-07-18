Promise = require 'bluebird'
logger = require('../config/logger').spawn("service:user:internals")
{singleRow} = require '../utils/util.sql.helpers'
userBlobsService = require('./service.user.blobs').instance
tables = require '../config/tables'

getImage = (entity) -> Promise.try ->
  if !entity?.account_image_id?
    throw new Error('entity.account_image_id missing cannot save image')
  userBlobsService.getById(entity.account_image_id)
  .then singleRow

getImageByUser = (auth_user_id) ->
  tables.auth.user()
  .select('blob')
  .where {auth_user_id}
  .innerJoin(tables.user.blobs.tableName,
    "#{tables.auth.user.tableName}.account_image_id",
    "#{tables.user.blobs.tableName}.id")
  .then singleRow

upsertImage = (entity, blob, tableFn = tables.auth.user) ->
  getImage(entity)
  .then (image) ->
    if image
      #update
      logger.debug "updating image for account_image_id: #{entity.account_image_id}"
      return userBlobsService.update {
        id: entity.account_image_id
        blob:blob
        auth_user_id: entity.id
      }
    #create
    logger.debug 'creating image'
    userBlobsService.create(blob:blob, auth_user_id: entity.id)
    .returning('id')
    .then singleRow
    .then (id) ->
      logger.debug "saving account_image_id: #{id}"
      tableFn().update(account_image_id: id)
      .where(id:entity.id)


module.exports = {
  getImage
  getImageByUser
  upsertImage
}
