Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:mls')
mlsHelpers = require './util.mlsHelpers'
retsService = require '../services/service.rets'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'
memoize = require 'memoizee'
analyzeValue = require '../../common/utils/util.analyzeValue'


# NOTE: This file a default task definition used for MLSs that have no special cases
NUM_ROWS_TO_PAGINATE = 2500


loadRawData = (subtask) ->
  numRowsToPageNormalize = subtask.data?.numRowsToPageNormalize || NUM_ROWS_TO_PAGINATE

  taskLogger = logger.spawn(subtask.task_name)
  if subtask.data?.limit?
    limit = subtask.data?.limit
    taskLogger.debug "limiting raw mls data to #{limit}"

  now = Date.now()

  refreshPromise = dataLoadHelpers.checkReadyForRefresh(subtask, targetHour: 1)  # target 1am every day
  rawLoadPromise = mlsHelpers.loadUpdates(subtask, dataSourceId: subtask.task_name, limit: limit)
  Promise.join refreshPromise, rawLoadPromise, (doRefresh, numRawRows) ->
    taskLogger.debug () -> "rows to normalize: #{numRawRows||0} (refresh: #{doRefresh})"
    if !doRefresh && !numRawRows
      return dataLoadHelpers.setLastUpdateTimestamp(subtask, now)
      .then () ->
        return 0

    recordCountsData =
      dataType: 'listing'
    activateData =
      deletes: dataLoadHelpers.DELETE.INDICATED
      startTime: now

    if doRefresh
      # whether or not we have data, we need to do some things when refreshing
      recordCountsData.deletes = dataLoadHelpers.DELETE.UNTOUCHED
      recordCountsData.indicateDeletes = true
      activateData.setRefreshTimestamp = true
      markUpToDatePromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "markUpToDate", manualData: {startTime: now}, replace: true})
    else
      recordCountsData.deletes = dataLoadHelpers.DELETE.INDICATED
      recordCountsData.indicateDeletes = false
      activateData.setRefreshTimestamp = false
      markUpToDatePromise = Promise.resolve()

    if numRawRows
      normalizePromise = jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRawRows, maxPage: numRowsToPageNormalize, laterSubtaskName: "normalizeData", mergeData: {dataType: 'listing', startTime: now}})
      recordCountsData.skipRawTable = false
    else
      normalizePromise = Promise.resolve()
      recordCountsData.skipRawTable = true

    recordCountsPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "recordChangeCounts", manualData: recordCountsData, replace: true})
    activatePromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "activateNewData", manualData: activateData, replace: true})

    Promise.join(recordCountsPromise, activatePromise, normalizePromise, markUpToDatePromise, () ->)
    .then () ->
      return numRawRows


normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: subtask.task_name
    dataSourceType: 'mls'
    buildRecord: mlsHelpers.buildRecord

# not used as a task since it is in normalizeData
# however this makes finalizeData accessible via the subtask script
finalizeDataPrep = (subtask) ->
  numRowsToPageFinalize = subtask.data?.numRowsToPageFinalize || NUM_ROWS_TO_PAGINATE

  tables.normalized.listing()
  .select('rm_property_id')
  .where
    batch_id: subtask.batch_id
    data_source_id: subtask.task_name
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: ids, maxPage: numRowsToPageFinalize, laterSubtaskName: "finalizeData"})

finalizeData = (subtask) ->
  impl = (id) ->
    mlsHelpers.finalizeData {subtask, id}
  Promise.map(subtask.data.values, impl)


markUpToDate = (subtask) ->
  mlsHelpers.markUpToDate(subtask)

subtasks = {
  loadRawData
  normalizeData
  finalizeDataPrep
  finalizeData
  activateNewData: dataLoadHelpers.activateNewData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  markUpToDate
}


factory = (taskName, overrideSubtasks) ->
  if overrideSubtasks?
    fullSubtasks = _.extend({}, subtasks, overrideSubtasks)
  else
    fullSubtasks = subtasks
  new TaskImplementation(taskName, fullSubtasks)

module.exports = memoize(factory, length: 1)
