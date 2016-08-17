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

NUM_ROWS_TO_PAGINATE_FOR_PHOTOS = 100

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
        # this makes debugging easier
        # MAIN REASON is WE are limited to a single login for many MLSes
        # THIS IS A MAJOR BOTTLE KNECK
        concurrency: 1
      })

storePhotos = (subtask) -> Promise.try () ->
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug subtask
  if !subtask?.data?.values.length
    taskLogger.debug 'no values to process for storePhotos'
    return

  Promise.each subtask.data.values, (row) ->
    mlsHelpers.storePhotos(subtask, row, tables.finalized.photo)

subtasks = {
  storePhotosPrep
  storePhotos]
}
module.exports = new TaskImplementation('photos', subtasks)
