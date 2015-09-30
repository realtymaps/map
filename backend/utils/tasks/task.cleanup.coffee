Promise = require 'bluebird'
dbs = require '../../config/dbs'
tables = require '../../config/tables'
logger = require '../../config/logger'
config = require '../../config/config'
TaskImplementation = require './util.taskImplementation'


_doTableDeletes = (tableList) -> Promise.try () ->
  if !tableList?.length
    return
    
  tableName = tableList.pop()?.raw_table_name
  logger.debug("cleaning up old raw table: #{tableName}")
  
  dbs.properties.knex.transaction (transaction) ->
    transaction.schema.dropTableIfExists(tableName)
    .then () ->
      tables.jobQueue.dataLoadHistory(transaction)
      .where(raw_table_name: tableName)
      .update(cleaned: true)
  .then () ->
    _doTableDeletes(tableList)


rawTables = (subtask) ->
  tables.jobQueue.dataLoadHistory()
  .select('raw_table_name')
  .where(cleaned: false)
  .whereNotNull('raw_table_name')
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_TABLE_DAYS} days'::INTERVAL")
  .then _doTableDeletes

subtaskErrors = (subtask) ->
  tables.jobQueue.subtaskErrorHistory()
  .whereRaw("finished < now_utc() - '#{config.CLEANUP.SUBTASK_ERROR_DAYS} days'::INTERVAL")
  .delete()
  .then (deleted) ->
    logger.debug "Deleted #{deleted} rows from subtask error history"

deleteMarkers = (subtask) ->
  tables.propertyData.deletes()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_MARKER_DAYS} days'::INTERVAL")
  .delete()
  .then (deleted) ->
    logger.debug "Deleted #{deleted} rows from delete marker table"

module.exports = new TaskImplementation
  rawTables: rawTables
  subtaskErrors: subtaskErrors
  deleteMarkers: deleteMarkers
