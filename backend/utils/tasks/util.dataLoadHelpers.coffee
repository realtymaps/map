dbs = require '../../config/dbs'
tables = require '../../config/tables'
Promise = require 'bluebird'
jobQueue = require '../util.jobQueue'


getRawTableName = (subtask, suffix) ->
  suffix = if suffix then "_#{suffix}" else ''
  "raw_#{subtask.task_name}#{suffix}_#{subtask.batch_id}"


createRawTempTable = (tableName, fields) ->
  dbs.properties.knex.schema.createTable tableName, (table) ->
    table.increments('rm_raw_id').notNullable()
    table.boolean('rm_valid')
    table.text('rm_error_msg')
    for fieldName in fields
      table.text(fieldName.replace(/\./g, ''))


_countInvalidRows = (knex, tableName, assignedFalse) ->
  asPrefix = if assignedFalse then 'invalids' else 'unvalids'
  knex
  .sum('invalid')
  .from () ->
    query = this
    .count('* AS invalid')
    .from(tableName)
    if assignedFalse
      query = query.where(rm_valid: false)
    else
      query = query.whereNull('rm_valid')
    query.as(asPrefix)

recordChangeCounts = (rawDataSuffix, destDataTable, subtask) ->
  Promise.try () ->
    if subtask.data.markOtherRowsDeleted
      # check if any rows will be left active after delete, and error if not; for efficiency, just grab the id of the
      # first such row rather than return all or count them all
      destDataTable()
      .select('rm_raw_id')
      .where(batch_id: subtask.batch_id)
      .whereNull('deleted')
      .limit(1)
      .then (row) ->
        if !row?[0]?
          throw new jobQueue.HardFail("operation would delete all active rows from #{subtask.task_name}")
      .then () ->
        # mark any rows not updated by this task (and not already marked) as deleted -- we only do this when doing a full
        # refresh of all data, because this would be overzealous if we're just doing an incremental update; the update
        # will resolve to a count of affected rows
        destDataTable()
        .whereNot(batch_id: subtask.batch_id)
        .whereNull('deleted')
        .update(deleted: subtask.batch_id)
  .then (deletedCount=0) ->
    # get a count of raw rows from all raw tables from this batch with rm_valid == false
    invalidSubquery = () -> _countInvalidRows(this, getRawTableName(subtask, rawDataSuffix), true)
    # get a count of raw rows from all raw tables from this batch with rm_valid == NULL
    unvalidatedSubquery = () -> _countInvalidRows(this, getRawTableName(subtask, rawDataSuffix), false)
    # get a count of rows from this batch with null change history, i.e. newly-inserted rows
    insertedSubquery = () ->
      destDataTable(this)
      .where(inserted: subtask.batch_id)
      .count('*')
    # get a count of rows from this batch without a null change history, i.e. newly-updated rows
    updatedSubquery = () ->
      destDataTable(this)
      .where(updated: subtask.batch_id)
      .count('*')
    touchedSubquery = () ->
      destDataTable(this)
      .where(batch_id: subtask.batch_id)
      .orWhere(deleted: subtask.batch_id)
      .count('*')
    tables.jobQueue.dataLoadHistory()
    .where(batch_id: subtask.batch_id)
    .update
      invalid_rows: invalidSubquery
      unvalidated_rows: unvalidatedSubquery
      inserted_rows: insertedSubquery
      updated_rows: updatedSubquery
      deleted_rows: deletedCount
      touched_rows: touchedSubquery


activateNewData = (subtask) ->
  # this function flips inactive rows to active, active rows to inactive, and deletes the now-inactive rows
  if subtask.data.deleteUntouchedRows
    # in this mode, we perform those actions to all rows on this data_source_id, because we assume this is a
    # full data sync, and if we didn't touch it that means it should be deleted
    tables.propertyData.combined()
    .where(data_source_id: subtask.task_name)
    .update(active: dbs.properties.knex.raw('NOT "active"'))
    .then () ->
      tables.propertyData.combined()
      .where
        data_source_id: subtask.task_name
        active: false
      .delete()
  else
    # in this mode, we're doing an incremental update, so we only want to perform those actions for rows with an
    # the rm_property_id that has been updated in this batch
    checkSubquery = () ->
      tables.propertyData.combined(this)
      .select('rm_property_id')
      .where
        data_source_id: subtask.task_name
        batch_id: subtask.batch_id
        active: false
    tables.propertyData.combined()
    .where
      data_source_id: subtask.task_name
      batch_id: subtask.batch_id
    .whereIn 'rm_property_id', checkSubquery
    .update(active: dbs.properties.knex.raw('NOT "active"'))
    .then () ->
      tables.propertyData.combined()
      .where
        data_source_id: subtask.task_name
        batch_id: subtask.batch_id
        active: false
      .delete()


module.exports =
  getRawTableName: getRawTableName
  createRawTempTable: createRawTempTable
  recordChangeCounts: recordChangeCounts
  activateNewData: activateNewData
