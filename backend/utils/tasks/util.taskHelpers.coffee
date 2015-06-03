# this is where common task-related code should go that isn't job-queue-infrastructure related or generic enough to go
# in a general util module

_ = require 'lodash'
jobQueue = require '../util.jobQueue'
dbs = require '../../config/dbs'


knex = jobQueue.knex


tables =
  dataLoadHistory: 'data_load_history'
  dataNormalizationConfig: 'data_normalization_config'
  mlsData: 'mls_data'


getRawTableName = (subtask, suffix) ->
  "raw_#{subtask.task_name}_#{suffix}__#{subtask.batch_id}"


# determines the start of the last time a task  ran, or defaults to the Epoch (Jan 1, 1970) if
# there are no runs found.  By default only considers successful runs.
getLastStartTime = (taskName, successOnly=true) ->
  criteria =
    name: taskName
    current: false
  if successOnly
    criteria.status = 'success'
  knex
  .table(jobQueue.tables.taskHistory)
  .max('started AS last_start_time')
  .where
  .then () ->
    result?[0]?.last_start_time || new Date(0)


createDataHistoryEntry = (entry) ->
  # insert a new entry into the data load history table -- this will be used for the raw table cleanup task, as
  # well as monitoring for problems with row parsing/validation
  dbs.properties.knex
  .insert entry
  .into(tables.dataLoadHistory)

  
createRawTempTable = (tableName, textFields, jsonFields) ->
  dbs.properties.knex.schema.createTable tableName, (table) ->
    table.increments('rm_raw_id').notNullable()
    table.boolean('rm_valid')
    table.text('rm_error_msg')
    for fieldName in textFields
      table.text(fieldName.replace(/\./g, ''))
    for fieldName in jsonFields
      table.json(fieldName.replace(/\./g, ''))

    
module.exports =
  tables: tables
  getLastStartTime: getLastStartTime
  createDataHistoryEntry: createDataHistoryEntry
  createRawTempTable: createRawTempTable
  getRawTableName: getRawTableName
