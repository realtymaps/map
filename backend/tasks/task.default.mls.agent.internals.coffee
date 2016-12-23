_ = require 'lodash'
Promise = require 'bluebird'
dbs = require '../config/dbs'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'
logger = require('../config/logger').spawn('task:mls:agent')


_finalizeEntry = ({entry, subtask, data_source_id}) -> Promise.try ->
  delete entry.deleted
  delete entry.rm_inserted_time
  delete entry.rm_modified_time

  entry.data_source_id = data_source_id
  entry.change_history = sqlHelpers.safeJsonArray(entry.change_history)

  entry


buildRecord = (stats, usedKeys, rawData, dataType, normalizedData, subtaskData) -> Promise.try () ->
# build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    ungrouped_fields: ungrouped
    deleted: null
    up_to_date: new Date(subtaskData.startTime)
  _.extend base, stats, data


finalizeData = ({subtask, data_source_uuid, data_source_id, transaction, delay}) ->
  delay ?= subtask.data?.delay || 100

  tables.normalized.agent({transaction, subid: data_source_id})
  .select('*')
  .where({data_source_uuid})
  .whereNull('deleted')
  .orderBy('data_source_uuid')
  .then (agentResults) ->

    if agentResults.length != 1
      logger.warn("Duplicate (#{agentResults.length}) agent entries found for uuid: #{data_source_uuid}")

    _finalizeEntry({entry: agentResults[0], subtask, data_source_id})
    .then (agent) ->
      Promise.delay(delay)  #throttle for heroku's sake
      .then () ->
        dbs.ensureTransaction transaction, 'main', (transaction) ->
          tables.finalized.agent({transaction})
          .where {
            data_source_uuid
            data_source_id
          }
          .delete()
          .then () ->
            tables.finalized.agent({transaction})
            .insert(agent)


ensureNormalizedTable = (subid) ->
  tableQuery = tables.normalized.agent({subid})
  tableName = tableQuery.tableName
  sqlHelpers.checkTableExists(tableQuery)
  .then (tableAlreadyExists) ->
    if tableAlreadyExists
      return
    dbs.get('normalized').schema.createTable tableName, (table) ->
      table.timestamp('rm_inserted_time', true).defaultTo(dbs.get('normalized').raw('now_utc()')).notNullable()
      table.timestamp('rm_modified_time', true).defaultTo(dbs.get('normalized').raw('now_utc()')).notNullable()
      table.text('batch_id').notNullable().index()
      table.text('deleted')
      table.timestamp('up_to_date', true).notNullable()
      table.json('change_history').defaultTo('[]').notNullable()
      table.text('data_source_uuid').notNullable()
      table.integer('rm_raw_id').notNullable()
      table.text('inserted').notNullable()
      table.text('updated')
      table.json('ungrouped_fields')
      table.integer('license_number').notNullable()
      table.text('agent_status').notNullable()
      table.text('email')
      table.text('full_name').notNullable()
      table.text('work_phone')
    .raw("CREATE UNIQUE INDEX ON #{tableName} (data_source_uuid)")
    .raw("CREATE TRIGGER update_rm_modified_time_#{tableName} BEFORE UPDATE ON #{tableName} FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column()")
    .raw("CREATE INDEX ON #{tableName} (inserted)")
    .raw("CREATE INDEX ON #{tableName} (deleted)")
    .raw("CREATE INDEX ON #{tableName} (updated)")


module.exports = {
  buildRecord
  finalizeData
  ensureNormalizedTable
}
