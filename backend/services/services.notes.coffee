_ = require 'lodash'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
dbs = require '../config/dbs'
logger = require('../config/logger').spawn('service:notes')
{joinColumns, basicColumns} = require '../utils/util.sql.columns'
toLeafletMarker = require('../utils/crud/extensions/util.crud.extension.user').route.toLeafletMarker
routeHelpers = require '../utils/util.route.helpers'


class NotesService extends ServiceCrud
  getAll: (entity = {}) =>
    query = @dbFn().select(joinColumns.notes).select("first_name", "last_name").select("address").innerJoin(
      tables.auth.user.tableName,
      "#{tables.user.notes.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id"
    ).leftJoin(
      tables.finalized.combined.tableName,
      "#{tables.user.notes.tableName}.rm_property_id",
      "#{tables.finalized.combined.tableName}.rm_property_id"
    )

    super(entity, {query})
    .then (notes) ->
      _.indexBy(toLeafletMarker(notes), 'id')

  enqueueEvent: ({promise, sub_type, type = 'propertySaved', entity, transaction}) ->
    promise
    .then (ret) ->
      profile = routeHelpers.currentProfile()
      logger.debug "#@@@@@@@@@@@@@@@@ eventsQueue type: #{type}@@@@@@@@@@@@@@@@@@@@@"
      tables.user.eventsQueue({transaction})
      .insert {
        auth_user_id: profile.auth_user_id
        project_id: profile.project_id
        type
        sub_type
        options: {
          id: entity.id
          rm_property_id: entity.rm_property_id
          text: entity.text
        }
      }
      .then () ->
        ret

  create: (entity, options = {}) ->
    options.returnKnex = true

    dbs.transaction (transaction) =>
      options.query = @dbFn({transaction})

      promise = super(entity, options).knex.returning('id')
      .then ([id]) ->
        entity.id = id
        entity

      @enqueueEvent {
        promise
        sub_type: 'note'
        entity
        transaction
      }

  update: (entity, options = {}) ->
    # filter out non-db fields that sometimes make it in like `icon` or `address`
    entity = _.pick entity, basicColumns.notes

    dbs.transaction (transaction) =>
      options.query = @dbFn({transaction})

      @enqueueEvent {
        promise: super(entity, options)
        sub_type: 'note'
        entity
        transaction
      }

  delete: (entity, options = {}) ->
    dbs.transaction (transaction) =>
      options.query = @dbFn({transaction})

      @enqueueEvent {
        promise: super(entity, options)
        sub_type: 'unNote'
        entity
        transaction
      }


instance = new NotesService(tables.user.notes, {debugNS: "NotesService"})
module.exports = instance
