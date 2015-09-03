Promise = require 'bluebird'
dbs = require '../../config/dbs'
tables = require '../../config/tables'
logger = require '../../config/logger'
config = require '../../config/config'


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


# TODO: since almost every task will have the same executeSubtask logic, we should bring that out into jobQueue
# TODO: and make it the default behavior if executeSubtask() isn't defined (just like we have with every other
# TODO: function in the implied task implementation interface.  Or maybe I should make a class and allow
# TODO: subclasses to override the parent functions -- that would pull the default behavior out of jobQueue.
subtasks =
  rawTables: rawTables
  subtaskErrors: subtaskErrors

module.exports =
  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtasks[subtask.name.replace(/[^_]+_/g,'')](subtask)
