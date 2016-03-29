Promise = require 'bluebird'
tables = require '../config/tables'
logger = require '../config/logger'
config = require '../config/config'
dbs = require '../config/dbs'
TaskImplementation = require './util.taskImplementation'


rawTables = (subtask) ->
  tables.jobQueue.dataLoadHistory()
  .select('raw_table_name')
  .where(cleaned: false)
  .whereNotNull('raw_table_name')
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_TABLE_DAYS} days'::INTERVAL")
  .map (loadEntry) ->
    logger.debug("cleaning up old raw table: #{loadEntry.raw_table_name}")

    # for now, try to clean the raw table from both dbs...  eventually we'll change this to just the raw db
    mainCleanup = dbs.get('main').schema.dropTableIfExists(loadEntry.raw_table_name)
    rawCleanup = dbs.get('raw_temp').schema.dropTableIfExists(loadEntry.raw_table_name)
    Promise.join mainCleanup, rawCleanup, () ->
      tables.jobQueue.dataLoadHistory()
      .where(raw_table_name: loadEntry.raw_table_name)
      .update(cleaned: true)

subtaskErrors = (subtask) ->
  tables.jobQueue.subtaskErrorHistory()
  .whereRaw("finished < now_utc() - '#{config.CLEANUP.SUBTASK_ERROR_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug "Deleted #{count} rows from subtask error history"

deleteMarkers = (subtask) ->
  tables.property.deletes()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_MARKER_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug "Deleted #{count} rows from delete marker table"

deleteInactiveRows = (subtask) ->
  tables.property.combined()
  .where(active: false)
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.INACTIVE_ROW_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug "Deleted #{count} rows from combined data table"


module.exports = new TaskImplementation {
  rawTables
  subtaskErrors
  deleteMarkers
  deleteInactiveRows
}
