Promise = require('bluebird')
tables = require('../config/tables')
logger = require('../config/logger').spawn('task:cleanup:internals')
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



tableNamesNotCleaned = (days = config.CLEANUP.OLD_TABLE_DAYS) ->
  _tableNames(cleaned: false)
  .whereRaw("rm_inserted_time < now_utc() - '#{days} days'::INTERVAL")


tablenamesNotDropped = (years = config.CLEANUP.OLD_TABLE_YEARS) ->
  _tableNames()
  .whereRaw("rm_inserted_time < now_utc() - '#{years} years'::INTERVAL")


cleanRawTables = (loadEntriesQuery = tableNamesNotCleaned()) ->
  rawLogger.debug -> loadEntriesQuery.toString()

  Promise.all loadEntriesQuery.map (loadEntry) ->
    rawLogger.debug -> loadEntry

    rawTempTable = tables.temp(subid: loadEntry.raw_table_name)
    loadEntryQuery = tables.jobQueue.dataLoadHistory().where loadEntry

    sqlHelpers.tableExists { dbFn: rawTempTable }
    .then (exists) ->
      if !exists
        rawLogger.debug -> "@@@@ table #{loadEntry.raw_table_name} is already gone deleting loadHistory entry"
        #already dropped or never existed
        loadEntryQuery.delete()
        return
      else
        #clean raw table
        rawLogger.debug -> "@@@@ table #{loadEntry.raw_table_name} cleaning all non errors"
        rawTempTable.whereNull('rm_error_msg').delete()
        .then () ->
          #mark as cleaned
          loadEntryQuery
          .update {cleaned: true}


dropRawTables = (loadEntriesQuery = tablenamesNotDropped()) ->
  Promise.all loadEntriesQuery.map (loadEntry) ->
    dbs.get('raw_temp').schema.dropTableIfExists(loadEntry.raw_table_name)
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
