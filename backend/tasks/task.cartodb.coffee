Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'
logger = require('../config/logger').spawn('task:cartodb')
loggerSyncPrep = require('../config/logger').spawn('task:cartodb:syncPep')
loggerSync = require('../config/logger').spawn('task:cartodb:sync')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{HardFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
cartodbSvc = require '../services/service.cartodb'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
dataLoadHelpers = require './util.dataLoadHelpers'


syncPrep = (subtask) ->
  loggerSyncPrep.debug "@@@@@@@@ cartodb:syncPrep @@@@@@@@"

  tables.cartodb.syncQueue()
  .select('id', 'fips_code', 'batch_id', 'errors')
  .then (rows) ->
    loggerSyncPrep.debug "@@@@@@@@ enqueueing rows @@@@@@@@"
    loggerSyncPrep.debug rows

    #NOTE Concurrency is 3 as this is the CartoDB's Import queue limit for our current plan
    Promise.all Promise.map rows, (row) ->
      jobQueue.queueSubsequentSubtask {
        subtask
        manualData: row
        laterSubtaskName: 'sync'
        concurrency: 3
      }
  .then () ->
    jobQueue.queueSubsequentSubtask {
      subtask
      laterSubtaskName: 'syncDone'
      manualData:
        startTime: Date.now()
    }

sync = (subtask) ->

  if !subtask.data?
    return

  row = subtask.data
  {fips_code} = row

  loggerSync.debug "uploading fips_code to cartodb: #{fips_code}"

  cartodbSvc.upload(fips_code)
  .then (tableNames) ->

    cartodbSvc.syncDequeue({
      fipsCode:fips_code
      tableNames
      batch_id: row.batch_id
      id: row.id
    })
    .catch (error) ->
      # back out bad import
      promises = []
      Promise.each tableNames, (tableName) ->
        logger.debug "backing out imports, tableName: #{tableName}"
        promises.push cartodbSvc.drop({fipsCode:fips_code, tableName})

      Promise.all promises
      .then () ->
        row.errors ?= []
        row.errors.push error.message

        tables.cartodb.syncQueue()
        .update(errors: row.errors)
        .where(id: row.id)
        .then () ->
          throw error
          
  .then () ->

    tables.cartodb.syncQueue()
    .where(id: row.id)
    .delete()
  .then () ->
    loggerSync.debug('All Sync CartoDB Success!!')
  .catch errorHandlingUtils.isUnhandled, (error) ->
    msg = 'failed to sync cartodb: '
    if typeof(error) == 'string'
      throw new errorHandlingUtils.PartiallyHandledError(msg + error)
    else if typeof(error) == 'object'
      if error.message
        throw new errorHandlingUtils.PartiallyHandledError(error, msg)
      else
        throw new errorHandlingUtils.PartiallyHandledError(msg + JSON.stringify(error))
  .catch (error) ->
    throw new HardFail(analyzeValue.getSimpleMessage(error))


syncDone = (subtask) ->
  logger.debug "@@@@@@@@@@ syncDone @@@@@@@@@@@@"
  logger.debug "marking lastRefreshTimestamp"
  dataLoadHelpers.setLastRefreshTimestamp(subtask)
  logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"


ready = () ->
  logger.debug -> 'ready'
  dataLoadHelpers.checkReadyForRefresh({task_name: 'cartodb'}, {targetHour: 2, targetDay: 'Saturday', runIfNever: true})
  .then (result) ->
    logger.debug ->'checkReadyForRefresh'
    logger.debug -> result
    result


module.exports = new TaskImplementation('cartodb', {syncPrep, sync, syncDone}, ready)
