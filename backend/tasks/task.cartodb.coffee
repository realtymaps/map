Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'
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

syncPrep = (subtask) ->
  loggerSyncPrep.debug "@@@@@@@@ cartodb:syncPrep @@@@@@@@"

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
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to sync cartodb')
  .catch (error) ->
    throw new HardFail(analyzeValue.getSimpleMessage(error))


syncDone = (subtask) ->
  logger.debug "@@@@@@@@@@ syncDone @@@@@@@@@@@@"
  logger.debug "marking lastRefreshTimestamp"
  dataLoadHelpers.setLastRefreshTimestamp(subtask)
  logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"


ready = () ->
  dataLoadHelpers.checkReadyForRefresh({task_name: 'cartodb'}, {targetHour: 2, targetDay: 'Saturday', runIfNever: true})
  .then (doRefresh) ->
    if !doRefresh
      # not ready yet
      return false
    # otherwise, use regular logic i.e. error retry delays
    return undefined


module.exports = new TaskImplementation('cartodb', {syncPrep, sync, syncDone}, ready)
