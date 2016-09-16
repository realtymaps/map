Promise = require 'bluebird'
logger = require('../config/logger').spawn("service:user:internals")
{singleRow} = require '../utils/util.sql.helpers'
tables = require '../config/tables'

getImage = (entity) ->
  if !entity?.account_image_id?
    return Promise.resolve []
  tables.user.blobs()
  .where(id: entity.account_image_id)
  .then singleRow

getImageByUser = (auth_user_id) ->
  if !auth_user_id
    return Promise.resolve []

  tables.auth.user()
  .select('blob')
  .where {auth_user_id}
  .innerJoin(tables.user.blobs.tableName,
    "#{tables.auth.user.tableName}.account_image_id",
    "#{tables.user.blobs.tableName}.id")
  .then singleRow

getImageByCompany = (company_id) ->
  if !company_id
    return Promise.resolve []

  tables.user.company()
  .select('blob')
  .where {company_id}
  .innerJoin(tables.user.blobs.tableName,
    "#{tables.user.company.tableName}.account_image_id",
    "#{tables.user.blobs.tableName}.id")
  .then singleRow

upsertImage = ({entity, blob, context}) ->
  context ?= 'user'

  if context == 'user'
    fkTable = tables.auth.user
    linkIdField = 'auth_user_id'
  else
    fkTable = tables.user.company
    linkIdField = 'company_id'


  getImage(entity)
  .then (image) ->
    if image
      #update
      logger.debug "updating image for account_image_id: #{entity.account_image_id}"
      return tables.user.blobs().update {
        id: entity.account_image_id
        blob:blob
        "#{linkIdField}": entity.id
      }
    #create
    logger.debug 'creating image'
    tables.user.blobs().insert(blob:blob, "#{linkIdField}": entity.id)
    .returning('id')
    .then singleRow
    .then (id) ->
      logger.debug "saving account_image_id: #{id}"
      fkTable().update(account_image_id: id)
      .where(id:entity.id)


module.exports = {
  getImage
  getImageByUser
  getImageByCompany
  upsertImage
}
