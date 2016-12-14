Promise = require('bluebird')
tables = require('../config/tables')
logger = require('../config/logger').spawn('task:cleanup')
config = require('../config/config')
dbs = require('../config/dbs')
TaskImplementation = require('./util.taskImplementation')
jobQueue = require('../services/service.jobQueue')
_ = require('lodash')
awsService = require '../services/service.aws'
internals = require './task.cleanup.internals'
jobQueueErrors = require '../utils/errors/util.error.jobQueue'


rawTables = () ->
  logger.debug -> 'Begin cleaning and dropping raw tables'

  internals.cleanRawTables()
  .then () ->
    logger.debug () -> 'done cleaning raw tables'
    internals.dropRawTables()
  .then () ->
    logger.debug () -> 'done dropping raw tables'


subtaskErrors = () ->
  tables.jobQueue.subtaskErrorHistory()
  .whereRaw("finished < now_utc() - '#{config.CLEANUP.SUBTASK_ERROR_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from subtask error history"


taskHistory = () ->
  tables.jobQueue.taskHistory()
  .where(current: false)
  .whereRaw("started < now_utc() - '#{config.CLEANUP.TASK_HISTORY_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from task history"


currentSubtasks = () ->
  dbs.transaction (transaction) ->
    tables.jobQueue.taskHistory({transaction})
    .select('name')
    .where(current: true)
    .whereRaw("finished < now_utc() - '#{config.CLEANUP.CURRENT_SUBTASKS_DAYS} days'::INTERVAL")
    .then (oldTasks) ->
      tables.jobQueue.currentSubtasks({transaction})
      .whereIn("task_name", oldTasks)
      .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from current subtasks"


deleteMarkers = () ->
  tables.deletes.combined()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_MARKER_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from delete marker table"


deleteParcels = () ->
  tables.deletes.parcel()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_PARCEL_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from delete parcels table"


deletePhotosPrep = (subtask) ->
  numRowsToPageDeletePhotos = subtask.data?.numRowsToPageDeletePhotos || internals.NUM_ROWS_TO_PAGINATE

  tables.deletes.photos()
  .select('key')
  .then (keys) ->
    keys = _.pluck(keys, 'key')
    jobQueue.queueSubsequentPaginatedSubtask {
      subtask
      totalOrList: keys
      maxPage: numRowsToPageDeletePhotos
      laterSubtaskName: "deletePhotos"
    }

deletePhotos = (subtask) ->
  logger.debug -> subtask

  Promise.map subtask.data.values, (key) -> Promise.try () ->
    logger.spawn(subtask.name).debug () -> "deleting: photo with key: #{key}"

    awsService.deleteObject
      extAcctName: config.EXT_AWS_PHOTO_ACCOUNT
      Key: key
    .then () ->
      logger.spawn(subtask.name).debug () -> 'successful deletion of aws photo ' + key

      tables.deletes.photos()
      .where {key}
      .del()
      .catch (error) ->
        throw new jobQueueErrors.SoftFail(error, "Transient Photo Deletion error; try again later. Failed to delete from database.")
    .catch (error) ->
      throw new jobQueueErrors.SoftFail(error, "Transient AWS Photo Deletion error; try again later")


module.exports = new TaskImplementation 'cleanup', {
  rawTables
  subtaskErrors
  taskHistory
  currentSubtasks
  deleteMarkers
  deleteParcels
  deletePhotosPrep
  deletePhotos
}
