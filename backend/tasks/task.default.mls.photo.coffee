Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger').spawn('task:mls:photo')
mlsHelpers = require './util.mlsHelpers'
retsService = require '../services/service.rets'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'
memoize = require 'memoizee'
analyzeValue = require '../../common/utils/util.analyzeValue'
internals = require './task.default.mls.photo.internals'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
jobQueueErrors = require '../utils/errors/util.error.jobQueue'


NUM_ROWS_TO_PAGINATE_FOR_PHOTOS = 500
MAX_RETRIES = 50


storePrep = (subtask) ->
  logger.debug () -> "storePrep for #{subtask.task_name}"
  numRowsToPagePhotos = subtask.data?.numRowsToPagePhotos || NUM_ROWS_TO_PAGINATE_FOR_PHOTOS

  mlsId = subtask.task_name.split('_')[0]
  logger.debug () -> "mlsId is #{mlsId}"

  stepNumOffset = 0
  _getRetriesIteratively = (minId=0) -> Promise.try () ->
    tables.deletes.retry_photos()
    .where(data_source_id: mlsId)
    .whereNot(batch_id: subtask.batch_id)
    .where('id', '>', minId)
    .where('retries', '<', MAX_RETRIES)
    .orderBy('id')
    .limit(numRowsToPagePhotos)
    .then (results) ->
      if !results.length
        return
      logger.debug () -> "Found #{results.length} retries in chunk"
      lastId = results[results.length-1].id
      for row,i in results
        results[i] =
          data_source_uuid: row.data_source_uuid
          photo_id: row.photo_id
      jobQueue.queueSubsequentSubtask({
        subtask
        laterSubtaskName: "store"
        stepNumOffset
        manualData: {values: results, chunk: stepNumOffset, count: results.length}
      })
      .then () ->
        # we are limited to a single login for many MLSes, so we have to prevent simultaneous instances of `store`
        stepNumOffset++
        _getRetriesIteratively(lastId)


  now = Date.now()
  jobQueue.queueSubsequentSubtask({
    subtask
    laterSubtaskName: "setLastUpdateTimestamp"
    manualData: {startTime: now}
  })
  .then () ->
    _getRetriesIteratively()
  .then () ->
    updatePromise = dataLoadHelpers.getLastUpdateTimestamp(subtask)
    lastModPromise = mlsHelpers.getMlsField(mlsId, 'photo_last_mod_time', 'listing').catch (err) ->
      throw new errorHandlingUtils.PartiallyHandledError(err, "Error retrieving photo_last_mod_time field for #{mlsId}")
    uuidPromise = mlsHelpers.getMlsField(mlsId, 'data_source_uuid', 'listing').catch (err) ->
      throw new errorHandlingUtils.PartiallyHandledError(err, "Error retrieving data_source_uuid field for #{mlsId}")
    photoIdPromise = mlsHelpers.getMlsField(mlsId, 'photo_id', 'listing').catch (err) ->
      throw new errorHandlingUtils.PartiallyHandledError(err, "Error retrieving photo_id field for #{mlsId}")

    # DON'T change this to Promise.join(promises...).then() syntax -- for some reason it doesn't work here
    Promise.join updatePromise, lastModPromise, uuidPromise, photoIdPromise, (updateThreshold, lastModField, uuidField, photoIdField) ->
      # grab all uuid's whose `lastModField` is greater than `updateThreshold` (datetime of last task run)
      dataOptions = {
        minDate: updateThreshold
        subLimit: numRowsToPagePhotos
        searchOptions: {Select: "#{uuidField},#{photoIdField}", offset: 1}
        listing_data: {lastModTime: lastModField}
      }

      if subtask.data.limit
        dataOptions.searchOptions.limit = subtask.data.limit

      handleChunk = (chunk) -> Promise.try () ->
        if !chunk?.length
          return
        logger.debug () -> "Found #{chunk.length} updated rows in chunk"
        for row,i in chunk
          chunk[i] =
            data_source_uuid: row[uuidField]
            photo_id: row[photoIdField]

        jobQueue.queueSubsequentSubtask({
          subtask
          laterSubtaskName: "store"
          stepNumOffset
          manualData: {values: chunk, chunk: stepNumOffset, count: chunk.length}
        })
        .then () ->
          # we are limited to a single login for many MLSes, so we have to prevent simultaneous instances of `store`
          stepNumOffset++

      logger.debug () -> "Getting data chunks for #{mlsId}: #{JSON.stringify(dataOptions)}"
      retsService.getDataChunks(mlsId, 'listing', dataOptions, handleChunk)
    .catch retsService.isMaybeTransientRetsError, (error) ->
      throw new jobQueueErrors.SoftFail(error, "Transient RETS error; try again later")
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, "Error getting list of updated records from RETS")

store = (subtask) -> Promise.try () ->
  taskLogger = logger.spawn(subtask.task_name)
  taskLogger.debug () -> "Page #{subtask.data.chunk}, Count: #{subtask.data.count}"
  if !subtask?.data?.values.length
    taskLogger.debug () -> "No photos to store for #{subtask.task_name}"
    return

  totalSuccess = 0
  totalSkips = 0
  totalErrors = 0
  totalUploads = 0

  Promise.each subtask.data.values, (idObj, i) ->
    taskLogger.debug () -> "processing photo_store value: #{i}/#{JSON.stringify(idObj)}"
    internals.storePhotos(subtask, idObj)
    .then ({successCtr, skipsCtr, errorsCtr, uploadsCtr}) ->
      totalSuccess += successCtr
      totalSkips += skipsCtr
      totalErrors += errorsCtr
      totalUploads += uploadsCtr
      taskLogger.debug () -> "Finished property #{idObj.data_source_uuid}"
  .then () ->
    taskLogger.debug () -> "Total photos uploaded: #{totalSuccess} | skipped: #{totalSkips} | errors: #{totalErrors} | uploads: #{totalUploads}"
  .catch retsService.isMaybeTransientRetsError, (error) ->
    throw new jobQueueErrors.SoftFail(error, "Transient RETS error; try again later")
  .catch errorHandlingUtils.isUnhandled, (err) ->
    taskLogger.debug () -> "#{analyzeValue.getFullDetails(err)}"
    throw err

clearRetries = (subtask) ->
  tables.deletes.retry_photos()
  .whereNot(batch_id: subtask.batch_id)
  .delete()

setLastUpdateTimestamp = (subtask) ->
  dataLoadHelpers.setLastUpdateTimestamp(subtask, subtask.data.startTime)

subtasks = {
  storePrep
  store
  clearRetries
  setLastUpdateTimestamp
}

factory = (taskName, overrideSubtasks) ->
  if overrideSubtasks?
    fullSubtasks = _.extend({}, subtasks, overrideSubtasks)
  else
    fullSubtasks = subtasks
  new TaskImplementation(taskName, fullSubtasks)

module.exports = memoize(factory, length: 1)
