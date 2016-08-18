Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:photos')
mlsHelpers = require './util.mlsHelpers'
retsService = require '../services/service.rets'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'

NUM_ROWS_TO_PAGINATE_FOR_PHOTOS = 100

storePrep = (subtask) ->
  numRowsToPagePhotos = subtask.data?.numRowsToPagePhotos || NUM_ROWS_TO_PAGINATE_FOR_PHOTOS
  mlsName = subtask.task_name.replace('_photos', '')

  updateThresholdPromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
  lastModPromise = mlsHelpers.getMlsField(mlsName, 'photo_last_mod_time')
  uuidPromise = mlsHelpers.getMlsField(mlsName, 'data_source_uuid')

  # grab all uuid's whose `lastModField` is greater than `updateThreshold` (datetime of last task run)
  Promise.join updateThresholdPromise, lastModPromise, uuidPromise, (updateThreshold, lastModField, uuidField) ->
    dataOptions = {minDate: updateThreshold, searchOptions: {Select: uuidField, offset: 1}, listing_data: {field: lastModField}}
    idsObj = {}
    retryPhotosPromise = tables.deletes.retry_photos()
    .where(data_source_id: mlsName)
    .whereNot(batch_id: subtask.batch_id)
    .then (rows) ->
      for row in rows
        idsObj[row[uuidField]] = true
    handleChunk = (chunk) -> Promise.try () ->
      if !chunk?.length
        return
      for row in chunk
        idsObj[row[uuidField]] = true
    updatedPhotosPromise = retsService.getDataChunks(mlsName, dataOptions, handleChunk)
    Promise.join retryPhotosPromise, updatedPhotosPromise, () ->
      jobQueue.queueSubsequentPaginatedSubtask({
        subtask
        totalOrList: Object.keys(idsObj)
        maxPage: numRowsToPagePhotos
        laterSubtaskName: "store"
        # this makes debugging easier
        # MAIN REASON is WE are limited to a single login for many MLSes
        # THIS IS A MAJOR BOTTLE KNECK
        concurrency: 1
      })

store = (subtask) -> Promise.try () ->
  mlsName = subtask.task_name.replace('_photos', '')
  taskLogger = logger.spawn(mlsName)
  taskLogger.debug subtask
  if !subtask?.data?.values.length
    taskLogger.debug "no values to process for #{mlsName} store photos}"
    return

  Promise.each subtask.data.values, (row) ->
    mlsHelpers.storePhotos(subtask, row, tables.finalized.photo)

ready = () ->
  # don't automatically run if corresponding MLS is running
  tables.jobQueue.taskHistory()
  .where(current: true)
  .where('name', @taskName.replace('_photos', ''))
  .whereNull('finished')
  .then (results) ->
    if results?.length
      # found an instance of this MLS, GTFO
      return false

    # if we didn't bail, signal to use normal enqueuing logic
    return undefined

subtasks = {
  storePrep
  store
}

factory = (taskName, overrideSubtasks) ->
  if overrideSubtasks?
    fullSubtasks = _.extend({}, subtasks, overrideSubtasks)
  else
    fullSubtasks = subtasks
  new TaskImplementation(taskName, fullSubtasks, ready)

module.exports = memoize(factory, length: 1)
