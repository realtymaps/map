Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:mls:listing')
mlsHelpers = require './util.mlsHelpers'
retsService = require '../services/service.rets'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'
memoize = require 'memoizee'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
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

  mlsHelpers.loadUpdates(subtask, dataType: 'agent', dataSourceId: mlsId, limit: limit)
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
      deletes: dataLoadHelpers.DELETE.UNTOUCHED
    normalizeData =
      dataType: 'agent'
      startTime: now

    markUpToDatePromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "markUpToDate", manualData: {startTime: now}, replace: true})
    normalizePromise = jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRawRows, maxPage: numRowsToPageNormalize, laterSubtaskName: "normalizeData", mergeData: normalizeData})
    recordCountsPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "recordChangeCounts", manualData: recordCountsData, replace: true})
    activatePromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "activateNewData", manualData: activateData, replace: true})

    Promise.join(recordCountsPromise, activatePromise, normalizePromise, markUpToDatePromise, () ->)
    .then () ->
      return numRawRows


normalizeData = (subtask) ->
  mlsId = subtask.task_name.split('_')[0]
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: mlsId
    dataSourceType: 'mls'
    buildRecord: internals.buildRecord
    skipFinalize: false


recordChangeCounts = (subtask) ->
  dataLoadHelpers.recordChangeCounts(subtask, indicateDeletes: false)


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
  Promise.each subtask.data.values, (id) ->
    internals.finalizeData {subtask, id}


markUpToDate = (subtask) ->
  mlsId = subtask.task_name.split('_')[0]
  mlsHelpers.getMlsField(mlsId, 'data_source_uuid', 'agent')
  .then (uuidField) ->
    dataOptions = {uuidField, minDate: 0, searchOptions: {limit: subtask.data.limit, Select: uuidField, offset: 1}}
    retsService.getDataChunks mlsId, 'agent', dataOptions, (chunk) -> Promise.try () ->
      if !chunk?.length
        return
      ids = _.pluck(chunk, uuidField)
      tables.normalized.agent()
      .where(data_source_id: mlsId)
      .whereIn('data_source_uuid', ids)
      .update(up_to_date: new Date(subtask.data.startTime), batch_id: subtask.batch_id, deleted: null)
      .returning('rm_property_id')
      .then (finalizeIds) ->
        if finalizeIds.length == 0
          return
        jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: finalizeIds, maxPage: 2500, laterSubtaskName: "finalizeData"})
    .then (count) ->
      logger.debug () -> "getDataChunks total: #{count}"
  .catch retsService.isMaybeTransientRetsError, (error) ->
    throw new SoftFail(error, "Transient RETS error; try again later")
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to make RETS data up-to-date')


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
