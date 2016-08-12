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

  refreshPromise = dataLoadHelpers.checkReadyForRefresh(subtask, targetHour: 1)  # target 1am every day
  rawLoadPromise = mlsHelpers.loadUpdates(subtask, dataSourceId: subtask.task_name, limit: limit)
  Promise.join refreshPromise, rawLoadPromise, (doRefresh, numRawRows) ->
    taskLogger.debug () -> "rows to normalize: #{numRawRows||0} (refresh: #{doRefresh})"
    if !doRefresh && !numRawRows
      dataLoadHelpers.setLastUpdateTimestamp(subtask)
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
  Promise.map subtask.data.values, (id) ->
    mlsHelpers.finalizeData {subtask, id}

storePhotosPrep = (subtask) ->
  numRowsToPagePhotos = subtask.data?.numRowsToPagePhotos || NUM_ROWS_TO_PAGINATE_FOR_PHOTOS

  updateThresholdPromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
  lastModPromise = mlsHelpers.getMlsField(subtask.task_name, 'photo_last_mod_time')
  uuidPromise = mlsHelpers.getMlsField(subtask.task_name, 'data_source_uuid')

  # grab all uuid's whose `lastModField` is greater than `updateThreshold` (datetime of last task run)
  Promise.join updateThresholdPromise, lastModPromise, uuidPromise, (updateThreshold, lastModField, uuidField) ->
    dataOptions = {minDate: updateThreshold, searchOptions: {Select: uuidField, offset: 1}, listing_data: {field: lastModField}}
    idsObj = {}
    retryPhotosPromise = tables.deletes.retry_photos()
    .where(data_source_id: subtask.task_name)
    .whereNot(batch_id: subtask.batch_id)
    .then (rows) ->
      for row in rows
        idsObj[row[uuidField]] = true
    handleChunk = (chunk) -> Promise.try () ->
      if !chunk?.length
        return
      for row in chunk
        idsObj[row[uuidField]] = true
    updatedPhotosPromise = retsService.getDataChunks(subtask.task_name, dataOptions, handleChunk)
    Promise.join retryPhotosPromise, updatedPhotosPromise, () ->
      jobQueue.queueSubsequentPaginatedSubtask({
        subtask
        totalOrList: Object.keys(idsObj)
        maxPage: numRowsToPagePhotos
        laterSubtaskName: "storePhotos"
        # concurrency: 1 # this makes debugging easier .. i think (nem)
      })

storePhotos = (subtask) -> Promise.try () ->
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug subtask
  if !subtask?.data?.values.length
    taskLogger.debug 'no values to process for storePhotos'
    return

  Promise.each subtask.data.values, (row) ->
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


markUpToDate = (subtask) ->
  mlsHelpers.markUpToDate(subtask)


clearPhotoRetries = (subtask) ->
  tables.deletes.retry_photos()
  .whereNot(batch_id: subtask.batch_id)
  .delete()


subtasks = {
  loadRawData
  normalizeData
  finalizeDataPrep
  finalizeData
  activateNewData: dataLoadHelpers.activateNewData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  storePhotosPrep
  storePhotos
  markUpToDate
  clearPhotoRetries
}


factory = (taskName, overrideSubtasks) ->
  if overrideSubtasks?
    fullSubtasks = _.extend({}, subtasks, overrideSubtasks)
  else
    fullSubtasks = subtasks
  new TaskImplementation(taskName, fullSubtasks, ready)

module.exports = memoize(factory, length: 1)
