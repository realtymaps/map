Promise = require 'bluebird'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn('task:cartodb:internals')
# coffeelint: enable=check_scope
loggerSync = require('../config/logger').spawn('task:cartodb:internals:sync')
tables = require '../config/tables'
cartodbSvc = require '../services/service.cartodb'

documentError = ({error, row}) ->
  row.errors ?= []
  row.errors.push error.message

  update = tables.cartodb.syncQueue()
  .update(errors: JSON.stringify row.errors)
  .where(id: row.id)

  loggerSync.debug -> update.toString()

  update.then () ->
    loggerSync.debug -> 'Re-throwing error'
    # must re-throw so the queue item stays there
    throw error

syncDequeue = ({tableNames, fips_code, row}) ->
  cartodbSvc.syncDequeue({
    fipsCode:fips_code
    tableNames
    batch_id: row.batch_id
    id: row.id
  })
  .catch (error) ->
    # back out bad import
    loggerSync.debug -> '@@@@@ Carto Error ATEMPTING BACKOUT @@@@@'
    loggerSync.debug -> tableNames

    promises = []
    Promise.each tableNames, (tableName) ->
      loggerSync.debug "backing out imports, tableName: #{tableName}"
      promises.push cartodbSvc.drop({fipsCode:fips_code, tableName})

    loggerSync.debug -> error

    Promise.all promises.then () ->
      documentError {row, error}

module.exports = {
  documentError
  syncDequeue
}
