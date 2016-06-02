Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:mls')
mlsHelpers = require './util.mlsHelpers'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'
PromiseExt = require '../extensions/promise'

# NOTE: This file a default task definition used for MLSs that have no special cases
NUM_ROWS_TO_PAGINATE = 2500
NUM_ROWS_TO_PAGINATE_FOR_PHOTOS = 100


loadRawData = (subtask) ->
  numRowsToPageNormalize = subtask.data?.numRowsToPageNormalize || NUM_ROWS_TO_PAGINATE

  taskLogger = logger.spawn(subtask.task_name)
  if subtask.data?.limit?
    limit = subtask.data?.limit
    taskLogger.debug "limiting raw mls data to #{limit}"

  now = Date.now()

  mlsHelpers.loadUpdates subtask,
    dataSourceId: subtask.task_name
    limit: limit
  .then ({numRawRows, deletes}) ->
    if !numRawRows
      taskLogger.debug("no rows to normalize")
      return 0
    taskLogger.debug("rows to normalize: #{numRawRows}")
    # now that we know we have data, queue up the rest of the subtasks (some have a flag depending
    # on whether this is a dump or an update)
    recordCountsPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "recordChangeCounts", manualData: {deletes, dataType: 'listing'}, replace: true})
    finalizePrepPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "finalizeDataPrep", replace: true})
    storePhotosPrepPromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "storePhotosPrep", replace: true})
    activatePromise = jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: "activateNewData", manualData: {deletes, startTime: now}, replace: true})
    normalizePromise = jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: numRawRows, maxPage: numRowsToPageNormalize, laterSubtaskName: "normalizeData", mergeData: {dataType: 'listing', startTime: now}})
    Promise.join(recordCountsPromise, finalizePrepPromise, storePhotosPrepPromise, activatePromise, normalizePromise, () ->)
    .then () ->
      return numRawRows

normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: subtask.task_name
    dataSourceType: 'mls'
    buildRecord: mlsHelpers.buildRecord

finalizeDataPrep = (subtask) ->
  numRowsToPageFinalize = subtask.data?.numRowsToPageFinalize || NUM_ROWS_TO_PAGINATE

  tables.property.listing()
  .select('rm_property_id')
  .where(batch_id: subtask.batch_id)
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: ids, maxPage: numRowsToPageFinalize, laterSubtaskName: "finalizeData"})

finalizeData = (subtask) ->
  Promise.map subtask.data.values, (id) ->
    mlsHelpers.finalizeData {subtask, id}

storePhotosPrep = (subtask) ->
  numRowsToPagePhotos = subtask.data?.numRowsToPagePhotos || NUM_ROWS_TO_PAGINATE_FOR_PHOTOS

  tables.property.listing()
  .select('data_source_id', 'data_source_uuid')
  .where(batch_id: subtask.batch_id)
  .then (rows) ->
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: rows, maxPage: numRowsToPagePhotos, laterSubtaskName: "storePhotos", concurrency: 1})

storePhotos = (subtask) -> Promise.try () ->
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug subtask
  #NOTE currently we can not do image download at high volume until we pool mls connections
  #swflmls, MRED and others only allow one connection at a time
  if !subtask?.data?.values.length
    taskLogger.debug 'no values to process for storePhotos'
    return

  #TODO: Promise.reduce / each in bluebird should work fine
  PromiseExt.reduceSeries subtask.data.values.map (row) -> ->
    mlsHelpers.storePhotos(subtask, row)


ready = () ->
  # don't automatically run if digimaps is running
  tables.jobQueue.taskHistory()
  .where
    current: true
    name: 'digimaps'
  .whereNull('finished')
  .then (results) ->
    if results?.length
      # found an instance of digimaps, GTFO
      return false

    # if we didn't bail, signal to use normal enqueuing logic
    return undefined


subtasks = {
  loadRawData
  normalizeData
  finalizeDataPrep
  finalizeData
  activateNewData: dataLoadHelpers.activateNewData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  storePhotosPrep
  storePhotos
}


module.exports = (taskName) ->
  new TaskImplementation(taskName, subtasks, ready)
