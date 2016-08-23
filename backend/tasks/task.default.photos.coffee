Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:photos')
mlsHelpers = require './util.mlsHelpers'
retsService = require '../services/service.rets'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'
memoize = require 'memoizee'
analyzeValue = require '../../common/utils/util.analyzeValue'

NUM_ROWS_TO_PAGINATE_FOR_PHOTOS = 100

storePrep = (subtask) ->
  logger.debug "storePrep for #{subtask.task_name}"
  numRowsToPagePhotos = subtask.data?.numRowsToPagePhotos || NUM_ROWS_TO_PAGINATE_FOR_PHOTOS
  mlsName = subtask.task_name.replace('_photos', '')
  logger.debug "mlsName is #{mlsName}"

  updateThresholdPromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
  lastModPromise = mlsHelpers.getMlsField(mlsName, 'photo_last_mod_time')
  uuidPromise = mlsHelpers.getMlsField(mlsName, 'data_source_uuid')

  # grab all uuid's whose `lastModField` is greater than `updateThreshold` (datetime of last task run)
  Promise.join updateThresholdPromise, lastModPromise, uuidPromise, (updateThreshold, lastModField, uuidField) ->
    logger.debug arguments
    dataOptions = {minDate: updateThreshold, searchOptions: {Select: uuidField, offset: 1}, listing_data: {field: lastModField}}
    logger.debug dataOptions
    idsObj = {}
    retryPhotosPromise = tables.deletes.retry_photos()
    .where(data_source_id: mlsName)
    .whereNot(batch_id: subtask.batch_id)
    .then (rows) ->
      logger.debug "Found #{rows.length} retries"
      for row in rows
        idsObj[row[uuidField]] = true
    handleChunk = (chunk) -> Promise.try () ->
      if !chunk?.length
        return
      logger.debug "Found #{chunk.length} updated rows in chunk"
      logger.debug chunk[0]
      for row in chunk
        idsObj[row[uuidField]] = true
    logger.debug "Getting data chunks for #{mlsName}"
    updatedPhotosPromise = retsService.getDataChunks(mlsName, dataOptions, handleChunk)
    Promise.join retryPhotosPromise, updatedPhotosPromise, () ->
      logger.debug "Got #{Object.keys(idsObj).length} updates + retries"
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
  logger.debug "store() for #{subtask.task_name}"
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug subtask
  if !subtask?.data?.values.length
    taskLogger.debug "no photos to store for #{subtask.task_name}"
    return

  Promise.each subtask.data.values, (data_source_uuid) ->
    taskLogger.debug "Calling mlsHelpers.storePhotosNew() for property #{data_source_uuid}"
    mlsHelpers.storePhotosNew(subtask, data_source_uuid)
    .then () ->
      taskLogger.debug "Finished property #{data_source_uuid}"
  .then () ->
    taskLogger.debug "Finished looping over properties"
  .catch (err) ->
    taskLogger.debug "#{analyzeValue.getSimpleDetails(err)}"
    throw err

clearRetries = (subtask) ->
  tables.deletes.retry_photos()
  .whereNot(batch_id: subtask.batch_id)
  .delete()

ready = () ->
  # don't automatically run if corresponding MLS is running
  query = tables.jobQueue.taskHistory()
  .where(current: true)
  .where('name', @taskName.replace('_photos', ''))
  .whereNull('finished')
  .then (results) ->
    if results?.length
      # found an instance of this MLS, GTFO
      return false

    # if we didn't bail, signal to use normal enqueuing logic
    return undefined

  logger.debug query.toString()
  query

subtasks = {
  storePrep
  store
  clearRetries
}

factory = (taskName, overrideSubtasks) ->
  if overrideSubtasks?
    fullSubtasks = _.extend({}, subtasks, overrideSubtasks)
  else
    fullSubtasks = subtasks
  new TaskImplementation(taskName, fullSubtasks, ready)

module.exports = memoize(factory, length: 1)
