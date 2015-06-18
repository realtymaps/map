# this is where common task-related code should go that isn't job-queue-infrastructure related or generic enough to go
# in a general util module

_ = require 'lodash'
tables = require '../../config/tables'
dbs = require '../../config/dbs'


getRawTableName = (subtask, suffix) ->
    suffix = if suffix then "_#{suffix}" else ''
    "raw_#{subtask.task_name}#{suffix}_#{subtask.batch_id}"


# determines the start of the last time a task  ran, or defaults to the Epoch (Jan 1, 1970) if
# there are no runs found.  By default only considers successful runs.
getLastStartTime = (taskName, successOnly=true) ->
    criteria =
        name: taskName
        current: false
    if successOnly
        criteria.status = 'success'
    tables.jobQueue.taskHistory()
    .max('started AS last_start_time')
    .where(criteria)
    .then (result) ->
        result?[0]?.last_start_time || new Date(0)

        
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
    getLastStartTime: getLastStartTime
    createRawTempTable: createRawTempTable
    getRawTableName: getRawTableName
