# this is where common task-related code should go that isn't job-queue-infrastructure related or generic enough to go
# in a general util module

jobQueue = require '../util.jobQueue'
dbs = require '../../config/dbs'


knex = jobQueue.knex

tables =
  dataLoadHistory: 'data_load_history'

  
# determines the start of the last time a task successfully ran, or defaults to the Epoch (Jan 1, 1970) if
# there are no successful runs
getLastSuccessStartTime = (taskName) ->
  knex
  .table(jobQueue.tables.taskHistory)
  .max('started AS last_success')
  .where
    name: taskName
    current: false
    status: 'success'
  .then () ->
    result?[0]?.last_success || new Date(0)


createDataHistoryEntry = (entry) ->
  # insert a new entry into the data load history table -- this will be used for the raw table cleanup task, as
  # well as monitoring for problems with row parsing/validation
  dbs.properties.knex
  .insert entry
  .into(tables.dataLoadHistory)

  
createRawTempTable = (tableName, fields) ->
  dbs.properties.knex.schema.createTable tableName, (table) ->
    table.increments('rm_raw_id').notNullable()
    table.boolean('rm_valid')
    fields.forEach (field) ->
      table.text(field.replace(/\./g, ''))


module.exports =
  tables: tables
  getLastSuccessStartTime: getLastSuccessStartTime
  createDataHistoryEntry: createDataHistoryEntry
  createRawTempTable: createRawTempTable
