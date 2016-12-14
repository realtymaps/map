Promise = require('bluebird')
tables = require('../config/tables')
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn('task:cleanup:internals')
# coffeelint: enable=check_scope
rawLogger = require('../config/logger').spawn('task:cleanup:internals:rawTables')
config = require('../config/config')
dbs = require('../config/dbs')
sqlHelpers = require '../utils/util.sql.helpers'

NUM_ROWS_TO_PAGINATE = 2500


_tableNames = (entity) ->
  q = tables.jobQueue.dataLoadHistory()
  .select('raw_table_name')
  .whereNotNull('raw_table_name')

  if entity
    q.where(entity)

  q


tableNamesNotCleaned = (days = config.CLEANUP.RAW_TABLE_CLEAN_DAYS) ->
  _tableNames(cleaned: false)
  .whereRaw("rm_inserted_time < now_utc() - '#{days} days'::INTERVAL")


tablenamesNotDropped = (days = config.CLEANUP.RAW_TABLE_DROP_DAYS) ->
  _tableNames()
  .whereRaw("rm_inserted_time < now_utc() - '#{days} days'::INTERVAL")


cleanRawTables = (loadEntriesQuery = tableNamesNotCleaned()) ->
  rawLogger.debug -> loadEntriesQuery.toString()

  Promise.each loadEntriesQuery, (loadEntry) ->
    rawLogger.debug -> loadEntry

    rawTempTable = tables.temp(subid: loadEntry.raw_table_name)
    loadEntryQuery = tables.jobQueue.dataLoadHistory().where(loadEntry)

    sqlHelpers.checkTableExists(rawTempTable)
    .then (exists) ->
      if !exists
        rawLogger.debug -> "@@@@ table #{loadEntry.raw_table_name} is already gone deleting loadHistory entry"
        #already dropped or never existed
        return loadEntryQuery.delete()

      #clean raw table
      rawLogger.debug -> "@@@@ table #{loadEntry.raw_table_name} cleaning all non errors"
      rawTempTable
      .whereNull('rm_error_msg')
      .delete()
      .then () ->
        #mark as cleaned
        loadEntryQuery
        .update {cleaned: true}
      .then () ->
        rawTempTable
        .count('*')
      .then (count) ->
        if !count
          # don't need to keep an empty table around
          dbs.get('raw_temp')
          .schema
          .dropTableIfExists(loadEntry.raw_table_name)


dropRawTables = (loadEntriesQuery = tablenamesNotDropped()) ->
  Promise.each loadEntriesQuery, (loadEntry) ->
    dbs.get('raw_temp')
    .schema
    .dropTableIfExists(loadEntry.raw_table_name)
    .then () ->
      tables.jobQueue.dataLoadHistory()
      .where(loadEntry)
      .delete()


module.exports = {
  NUM_ROWS_TO_PAGINATE
  tableNamesNotCleaned
  tablenamesNotDropped
  cleanRawTables
  dropRawTables
}
