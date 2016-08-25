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

NUM_ROWS_TO_PAGINATE_FOR_PHOTOS = 250
MAX_PAGES = 0

storePrep = (subtask) ->
  logger.debug "storePrep for #{subtask.task_name}"
  numRowsToPagePhotos = subtask.data?.numRowsToPagePhotos || NUM_ROWS_TO_PAGINATE_FOR_PHOTOS
  mlsName = subtask.task_name.replace('_photos', '')
  logger.debug "mlsName is #{mlsName}"

  updateThresholdPromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
  lastModPromise = mlsHelpers.getMlsField(mlsName, 'photo_last_mod_time')
  uuidPromise = mlsHelpers.getMlsField(mlsName, 'data_source_uuid')
  photoIdPromise = mlsHelpers.getMlsField(mlsName, 'photo_id')

  # grab all uuid's whose `lastModField` is greater than `updateThreshold` (datetime of last task run)
  Promise.join updateThresholdPromise, lastModPromise, uuidPromise, photoIdPromise, (updateThreshold, lastModField, uuidField, photoIdField) ->
    logger.debug arguments
    dataOptions = {minDate: updateThreshold, searchOptions: {Select: "#{uuidField},#{photoIdField}", offset: 1}, listing_data: {field: lastModField}}
    if MAX_PAGES
      dataOptions.searchOptions.limit = NUM_ROWS_TO_PAGINATE_FOR_PHOTOS * MAX_PAGES
    logger.debug dataOptions
    idsObj = {}
    retryPhotosPromise = tables.deletes.retry_photos()
    .where(data_source_id: mlsName)
    .whereNot(batch_id: subtask.batch_id)
    .then (rows) ->
      logger.debug "Found #{rows.length} retries"
      for row in rows
        idsObj[row[uuidField]] =
          data_source_uuid: row[uuidField]
          photo_id: row[photoIdField]

    handleChunk = (chunk) -> Promise.try () ->
      if !chunk?.length
        return
      logger.debug "Found #{chunk.length} updated rows in chunk"
      for row in chunk
        idsObj[row[uuidField]] =
          data_source_uuid: row[uuidField]
          photo_id: row[photoIdField]

    logger.debug "Getting data chunks for #{mlsName}"
    updatedPhotosPromise = retsService.getDataChunks(mlsName, dataOptions, handleChunk)
    Promise.join retryPhotosPromise, updatedPhotosPromise, () ->
      logger.debug "Got #{Object.keys(idsObj).length} updates + retries"
      jobQueue.queueSubsequentPaginatedSubtask({
        subtask
        totalOrList: _.values(idsObj)
        maxPage: numRowsToPagePhotos
        laterSubtaskName: "store"
        # this makes debugging easier
        # MAIN REASON is WE are limited to a single login for many MLSes
        # THIS IS A MAJOR BOTTLE KNECK
        concurrency: 1
      })

store = (subtask) -> Promise.try () ->
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug "Page #{subtask.data.i}/#{subtask.data.of} Offset: #{subtask.data.offset} Count: #{subtask.data.count}"
  if !subtask?.data?.values.length
    taskLogger.debug "No photos to store for #{subtask.task_name}"
    return

  totalSuccess = 0
  totalSkips = 0
  totalErrors = 0

  Promise.each subtask.data.values, (idObj) ->
    # taskLogger.debug "Calling mlsHelpers.storePhotosNew() for property #{idObj.data_source_uuid}"
    mlsHelpers.storePhotosNew(subtask, idObj)
    .then ({successCtr, skipsCtr, errorsCtr}) ->
      totalSuccess += successCtr
      totalSkips += skipsCtr
      totalErrors += errorsCtr
      # taskLogger.debug "Finished property #{idObj.data_source_uuid}"
  .then () ->
    taskLogger.debug "Total photos uploaded: #{totalSuccess} | skipped: #{totalSkips} | errors: #{totalErrors}"
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
