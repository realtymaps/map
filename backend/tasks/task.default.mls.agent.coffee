Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:mls:agent')
mlsHelpers = require './util.mlsHelpers'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'
memoize = require 'memoizee'
internals = require './task.default.mls.agent.internals'


# NOTE: This file is a default task definition used for MLSs that have no special cases
NUM_ROWS_TO_PAGINATE = 2500


loadRawData = (subtask) ->
  mlsId = subtask.task_name.split('_')[0]
  now = Date.now()
  numRowsToPageNormalize = subtask.data?.numRowsToPageNormalize || NUM_ROWS_TO_PAGINATE
  taskLogger = logger.spawn(subtask.task_name)
  if subtask.data?.limit?
    limit = subtask.data?.limit
    taskLogger.debug "limiting raw mls data to #{limit}"

  mlsHelpers.loadUpdates(subtask, dataType: 'agent', dataSourceId: mlsId, limit: limit, fullRefresh: true)
  .then (numRawRows) ->
    taskLogger.debug () -> "rows to normalize: #{numRawRows||0}"
    if !numRawRows
      return dataLoadHelpers.setLastUpdateTimestamp(subtask, now)
      .then () ->
        return 0

    recordCountsData =
      dataType: 'agent'
      deletes: dataLoadHelpers.DELETE.UNTOUCHED
      skipRawTable: false
    activateData =
      startTime: now
      setRefreshTimestamp: true
    normalizeData =
      dataType: 'agent'
      startTime: now

    normalizePromise = jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRawRows, maxPage: numRowsToPageNormalize, laterSubtaskName: "normalizeData", mergeData: normalizeData})
    recordCountsPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "recordChangeCounts", manualData: recordCountsData, replace: true})
    activatePromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "activateNewData", manualData: activateData, replace: true})

    Promise.join(recordCountsPromise, activatePromise, normalizePromise, () ->)
    .then () ->
      return numRawRows


normalizeData = (subtask) ->
  mlsId = subtask.task_name.split('_')[0]
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: mlsId
    dataSourceType: 'mls'
    buildRecord: internals.buildRecord
    skipFinalize: false
    idField: 'data_source_uuid'


recordChangeCounts = (subtask) ->
  data_source_id = subtask.task_name.split('_')[0]
  dataLoadHelpers.recordChangeCounts(subtask, {indicateDeletes: false, data_source_id})


# not used as a task since it is in normalizeData
# however this makes finalizeData accessible via the subtask script
finalizeDataPrep = (subtask) ->
  mlsId = subtask.task_name.split('_')[0]
  numRowsToPageFinalize = subtask.data?.numRowsToPageFinalize || NUM_ROWS_TO_PAGINATE

  tables.normalized.agent()
  .select('rm_property_id')
  .where
    batch_id: subtask.batch_id
    data_source_id: mlsId
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: ids, maxPage: numRowsToPageFinalize, laterSubtaskName: "finalizeData"})


finalizeData = (subtask) ->
  data_source_id = subtask.task_name.split('_')[0]
  Promise.each subtask.data.values, (data_source_uuid) ->
    internals.finalizeData {subtask, data_source_uuid, data_source_id}


activateNewData = (subtask) ->
  data_source_id = subtask.task_name.split('_')[0]
  dataLoadHelpers.activateNewData(subtask, {deletes: dataLoadHelpers.DELETE.UNTOUCHED, tableProp: 'agent', skipIndicatedDeletes: true, data_source_id})


subtasks = {
  loadRawData
  normalizeData
  recordChangeCounts
  finalizeDataPrep
  finalizeData
  activateNewData
}


factory = (taskName, overrideSubtasks) ->
  if overrideSubtasks?
    fullSubtasks = _.extend({}, subtasks, overrideSubtasks)
  else
    fullSubtasks = subtasks
  new TaskImplementation(taskName, fullSubtasks)

module.exports = memoize(factory, length: 1)
