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
internals = require './task.default.mls.listing.internals'


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

  maintenancePromise = dataLoadHelpers.checkReadyForRefresh(subtask, targetHour: 1)  # target 1am every day
  dataLoadPromise = mlsHelpers.loadUpdates(subtask, dataType: 'listing', dataSourceId: mlsId, limit: limit)
  Promise.join maintenancePromise, dataLoadPromise, (dailyMaintenance, numRawRows) ->
    taskLogger.debug () -> "rows to normalize: #{numRawRows||0} (refresh: #{dailyMaintenance})"
    if !dailyMaintenance && !numRawRows
      return dataLoadHelpers.setLastUpdateTimestamp(subtask, now)
      .then () ->
        return 0

    recordCountsData =
      dataType: 'listing'
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
      normalizePromise = jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRawRows, maxPage: numRowsToPageNormalize, laterSubtaskName: "normalizeData", mergeData: {dataType: 'listing', startTime: now, dailyMaintenance}})
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
  mlsId = subtask.task_name.split('_')[0]
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: mlsId
    dataSourceType: 'mls'
    buildRecord: internals.buildRecord
    skipFinalize: subtask.data.dailyMaintenance


recordChangeCounts = (subtask) ->
  data_source_id = subtask.task_name.split('_')[0]
  dataLoadHelpers.recordChangeCounts(subtask, {indicateDeletes: false, data_source_id})


# not used as a task since it is in normalizeData
# however this makes finalizeData accessible via the subtask script
finalizeDataPrep = (subtask) ->
  mlsId = subtask.task_name.split('_')[0]
  numRowsToPageFinalize = subtask.data?.numRowsToPageFinalize || NUM_ROWS_TO_PAGINATE

  tables.normalized.listing()
  .select('rm_property_id')
  .where
    batch_id: subtask.batch_id
    data_source_id: mlsId
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: ids, maxPage: numRowsToPageFinalize, laterSubtaskName: "finalizeData"})

finalizeData = (subtask) ->
  data_source_id = subtask.task_name.split('_')[0]
  Promise.each subtask.data.values, (id) ->
    internals.finalizeData {subtask, id, data_source_id}


markUpToDate = (subtask) ->
  mlsId = subtask.task_name.split('_')[0]
  mlsHelpers.getMlsField(mlsId, 'data_source_uuid', 'listing')
  .then (uuidField) ->
    dataOptions = {uuidField, minDate: 0, searchOptions: {limit: subtask.data.limit, Select: uuidField, offset: 1}}
    chunkNum = 0
    retsService.getDataChunks mlsId, 'listing', dataOptions, (chunk) -> Promise.try () ->
      if !chunk?.length
        return
      chunkNum++
      thisChunkNum = chunkNum
      ids = _.pluck(chunk, uuidField)
      tables.normalized.listing()
      .where(data_source_id: mlsId)
      .whereIn('data_source_uuid', ids)
      .update(up_to_date: new Date(subtask.data.startTime), batch_id: subtask.batch_id, deleted: null)
      .returning('rm_property_id')
      .then (finalizeIds) ->
        if finalizeIds.length == 0
          return
        jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: finalizeIds, maxPage: 2500, laterSubtaskName: "finalizeData", mergeData: {chunk: thisChunkNum}})
    .then (count) ->
      logger.debug () -> "getDataChunks total: #{count}"
  .catch retsService.isMaybeTransientRetsError, (error) ->
    throw new SoftFail(error, "Transient RETS error; try again later")
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to make RETS data up-to-date')


activateNewData = (subtask) ->
  data_source_id = subtask.task_name.split('_')[0]
  dataLoadHelpers.activateNewData(subtask, {deletes: subtask.data.deletes, data_source_id})


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
