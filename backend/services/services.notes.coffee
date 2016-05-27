_ = require 'lodash'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
dbs = require '../config/dbs'
moment = require 'moment'
logger = require('../config/logger').spawn('service:notes')
{joinColumns} = require '../utils/util.sql.columns'
toLeafletMarker = require('../utils/crud/extensions/util.crud.extension.user').route.toLeafletMarker


class NotesService extends ServiceCrud
  getAll: (entity = {}) ->
    query = @dbFn().select(joinColumns.notes).select("first_name", "last_name").innerJoin(
      tables.auth.user.tableName,
      "#{tables.user.notes.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id"
    )

    super(entity, query: query).then (notes) ->
      return toLeafletMarker notes


instance = new NotesService(tables.user.notes, {debugNS: "NotesService"})
module.exports = instance
