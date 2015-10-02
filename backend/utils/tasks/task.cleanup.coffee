Promise = require 'bluebird'
tables = require '../../config/tables'
logger = require '../../config/logger'
config = require '../../config/config'
dbs = require '../../config/dbs'
TaskImplementation = require './util.taskImplementation'

_doTableDeletes = (tableList) ->
  Promise.map tableList, (tableEntry) ->
    logger.debug("cleaning up old raw table: #{tableEntry.raw_table_name}")

    dbs.get('raw_temp').schema.dropTableIfExists(tableName)
    .then () ->
      tables.jobQueue.dataLoadHistory(transaction)
      .where(raw_table_name: tableName)
      .update(cleaned: true)


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
