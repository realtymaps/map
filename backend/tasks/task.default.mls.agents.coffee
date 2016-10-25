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


# NOTE: This file is a default task definition used for MLSs that have no special cases
NUM_ROWS_TO_PAGINATE = 2500


loadRawData = (subtask) ->
  now = Date.now()
  numRowsToPageNormalize = subtask.data?.numRowsToPageNormalize || NUM_ROWS_TO_PAGINATE
  taskLogger = logger.spawn(subtask.task_name)
  if subtask.data?.limit?
    limit = subtask.data?.limit
    taskLogger.debug "limiting raw mls data to #{limit}"

  mlsHelpers.loadUpdates(subtask, dataSourceId: subtask.task_name.split('_')[0], limit: limit)
  .then (numRawRows) ->
    taskLogger.debug () -> "rows to normalize: #{numRawRows||0}"
    if !numRawRows
      return dataLoadHelpers.setLastUpdateTimestamp(subtask, now)
      .then () ->
        return 0

    recordCountsData =
      dataType: subtask.data.dataType
    activateData =
      startTime: now

    if dailyMaintenance
      # whether or not we have data, we need to do some things when refreshing
      recordCountsData.deletes = dataLoadHelpers.DELETE.UNTOUCHED
      activateData.setRefreshTimestamp = true
      activateData.deletes = dataLoadHelpers.DELETE.UNTOUCHED
      markUpToDatePromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "markUpToDate", manualData: {startTime: now}, replace: true})
    else
      recordCountsData.deletes = dataLoadHelpers.DELETE.INDICATED
      activateData.setRefreshTimestamp = false
      activateData.deletes = dataLoadHelpers.DELETE.INDICATED
      markUpToDatePromise = Promise.resolve()

    if numRawRows
      normalizePromise = jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRawRows, maxPage: numRowsToPageNormalize, laterSubtaskName: "normalizeData", mergeData: {dataType: subtask.data.dataType, startTime: now, dailyMaintenance}})
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
    skipFinalize: subtask.data.dailyMaintenance


recordChangeCounts = (subtask) ->
  dataLoadHelpers.recordChangeCounts(subtask, indicateDeletes: false)


# not used as a task since it is in normalizeData
# however this makes finalizeData accessible via the subtask script
finalizeDataPrep = (subtask) ->
  numRowsToPageFinalize = subtask.data?.numRowsToPageFinalize || NUM_ROWS_TO_PAGINATE

  tables.normalized[subtask.data.dataType]()
  .select('rm_property_id')
  .where
      batch_id: subtask.batch_id
      data_source_id: subtask.task_name
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: ids, maxPage: numRowsToPageFinalize, laterSubtaskName: "finalizeData"})

finalizeData = (subtask) ->
  Promise.each subtask.data.values, (id) ->
    mlsHelpers.finalizeData {subtask, id}


markUpToDate = (subtask) ->
  mlsHelpers.markUpToDate(subtask)


activateNewData = (subtask) ->
  dataLoadHelpers.activateNewData(subtask, {deletes: subtask.data.deletes})


subtasks = {
  loadRawData
  normalizeData
  recordChangeCounts
  finalizeDataPrep
  finalizeData
  activateNewData
  markUpToDate
}


factory = (taskName, overrideSubtasks) ->
  if overrideSubtasks?
    fullSubtasks = _.extend({}, subtasks, overrideSubtasks)
  else
    fullSubtasks = subtasks
  new TaskImplementation(taskName, fullSubtasks)

module.exports = memoize(factory, length: 1)
