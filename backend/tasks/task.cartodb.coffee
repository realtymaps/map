request = require 'request'
cartodbConfig = require '../config/cartodb/cartodb'
Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'
request = Promise.promisify(request)
logger = require('../config/logger').spawn('backend:task:cartodb')
loggerSyncPrep = require('../config/logger').spawn('backend:task:cartodb:syncPep')
loggerSync = require('../config/logger').spawn('backend:task:cartodb:sync')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
cartodbSvc = require '../services/service.cartodb'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
dataLoadHelpers = require './util.dataLoadHelpers'


NUM_ROWS_TO_PAGINATE = 10

###eslint-disable###
wake = (subtask) -> Promise.try ->
  ###eslint-enable###
  cartodbConfig()
  .then (config) ->
    logger.debug '@@@@ cartodb config @@@@'
    logger.debug config

    Promise.all Promise.map config.WAKE_URLS, (url) ->
      logger.debug("Posting Wake URL: #{url}")
      request {
        url: 'http:' + url
        headers:
          'Content-Type': 'application/json;charset=utf-8'
      }

    .then () ->
      logger.debug('All Wake Success!!')
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'failed wake cartodb')
    .catch (error) ->
      throw new SoftFail(analyzeValue.getSimpleMessage(error))

syncPrep = (subtask) ->
  loggerSyncPrep.debug "@@@@@@@@ cartodb:syncPrep @@@@@@@@"

  dataLoadHelpers.checkReadyForRefresh(subtask, {targetHour: 2, targetDay: 'Saturday', runIfNever: true})
  .then (doRefresh) ->
    if !doRefresh
      loggerSyncPrep.debug 'not doing refresh'
      return

    maxPage = subtask?.data?.numRowsToPageProcessEvents || NUM_ROWS_TO_PAGINATE

    tables.cartodb.syncQueue()
    .select('id', 'fips_code', 'batch_id')
    .then (rows) ->
      loggerSyncPrep.debug "@@@@@@@@ enqueueing rows @@@@@@@@"
      loggerSyncPrep.debug rows

      jobQueue.queueSubsequentPaginatedSubtask {
        subtask
        totalOrList: rows
        maxPage
        laterSubtaskName: 'sync'
        mergeData: {}
      }
    .then () ->
      jobQueue.queueSubsequentSubtask {
        subtask
        laterSubtaskName: 'syncDone'
        manualData:
          startTime: Date.now()
      }

sync = (subtask) ->

  if !subtask.data?.values?.length
    return

  Promise.all Promise.map subtask.data.values, (row) ->
    {fips_code} = row

    loggerSync.debug "uploading fips_code to cartodb: #{fips_code}"

    cartodbSvc.parcel.upload(fips_code)
    .then () ->
      loggerSync.debug "syncing fips_code to cartodb: #{fips_code}"
      cartodbSvc.parcel.synchronize(fips_code)
    .then () ->
      loggerSync.debug "dequeing: id: #{row.id}, batch_id: #{row.batch_id}"
      tables.cartodb.syncQueue()
      .where(id: row.id)
      .delete()
  .then () ->
    loggerSync.debug('All Sync CartoDB Success!!')
  .catch errorHandlingUtils.isUnhandled, (error) ->
    console.log error.stack
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to sync cartodb')
  .catch (error) ->
    throw new HardFail(analyzeValue.getSimpleMessage(error))


syncDone = (subtask) ->
  logger.debug "@@@@@@@@@@ syncDone @@@@@@@@@@@@"
  logger.debug "marking lastRefreshTimestamp"
  dataLoadHelpers.setLastRefreshTimestamp(subtask)
  logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"


module.exports = new TaskImplementation('cartodb', {
  wake
  syncPrep
  sync
  syncDone
})
