Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task.mls')
mlsHelpers = require './util.mlsHelpers'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'
PromiseExt = require '../extensions/promise'

# NOTE: This file a default task definition used for MLSs that have no special cases
NUM_ROWS_TO_PAGINATE = 2500


loadRawData = (subtask) ->
  if subtask.data?.limit?
    limit = subtask.data?.limit
    logger.debug "limiting raw mls data to #{limit}"

  now = Date.now()

  mlsHelpers.loadUpdates subtask,
    dataSourceId: subtask.task_name
    limit: limit
  .then ({numRawRows, deletes}) ->
    if numRawRows == 0
      return 0
    # now that we know we have data, queue up the rest of the subtasks (some have a flag depending
    # on whether this is a dump or an update)
    recordCountsPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "recordChangeCounts", manualData: {deletes, dataType: 'listing'}, replace: true})
    finalizePrepPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "finalizeDataPrep", replace: true})
    storePhotosPrepPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "storePhotosPrep", replace: true})
    activatePromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "activateNewData", manualData: {deletes, startTime: now}, replace: true})
    Promise.join recordCountsPromise, finalizePrepPromise, storePhotosPrepPromise, activatePromise, () ->
      numRawRows
  .then (numRows) ->
    if numRows == 0
      return
    logger.debug("num rows to normalize: #{numRows}")
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRows, maxPage: NUM_ROWS_TO_PAGINATE, laterSubtaskName: "normalizeData", mergeData: {dataType: 'listing', startTime: now}})

normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: subtask.task_name
    dataSourceType: 'mls'
    buildRecord: mlsHelpers.buildRecord

finalizeDataPrep = (subtask) ->
  tables.property.listing()
  .select('rm_property_id')
  .where(batch_id: subtask.batch_id)
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: ids, maxPage: NUM_ROWS_TO_PAGINATE, laterSubtaskName: "finalizeData"})

finalizeData = (subtask) ->
  Promise.map subtask.data.values, (id) ->
    mlsHelpers.finalizeData {subtask, id}

storePhotosPrep = (subtask) ->
  tables.property.listing()
  .select('data_source_id', 'data_source_uuid')
  .where(batch_id: subtask.batch_id)
  .then (rows) ->
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: rows, maxPage: NUM_ROWS_TO_PAGINATE, laterSubtaskName: "storePhotos", concurrency: 1})

storePhotos = (subtask) -> Promise.try () ->
  logger.debug subtask
  #NOTE currently we can not do image download at high volume until we pool mls connections
  #swflmls, MRED and others only allow one connection at a time
  if !subtask?.data?.values.length
    logger.debug 'no values to process for storePhotos'
    return

  PromiseExt.reduceSeries subtask.data.values.map (row) -> ->
    mlsHelpers.storePhotos(subtask, row)

module.exports = new TaskImplementation {
  loadRawData
  normalizeData
  finalizeDataPrep
  finalizeData
  activateNewData: dataLoadHelpers.activateNewData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  storePhotosPrep
  storePhotos
}
