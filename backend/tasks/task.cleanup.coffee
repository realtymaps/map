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
  .then (counts) ->
    logger.debug () -> 'done cleaning raw tables'
    logger.info("Cleaned #{counts.cleans} raw temp tables")
    logger.info("Dropped #{counts.drops} empty raw temp tables")
    logger.info("Skipped #{counts.skips} missing raw temp tables (during cleaning phase)")
    internals.dropRawTables()
  .then (counts) ->
    logger.debug () -> 'done dropping raw tables'
    logger.info("Dropped #{counts.drops} old raw temp tables")
    logger.info("Skipped #{counts.skips} missing raw temp tables (during drop phase)")


subtaskErrors = () ->
  tables.jobQueue.subtaskErrorHistory()
  .whereRaw("finished < now_utc() - '#{config.CLEANUP.SUBTASK_ERROR_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.info("Deleted #{count} rows from subtask error history")


taskHistory = () ->
  tables.jobQueue.taskHistory()
  .where(current: false)
  .whereRaw("started < now_utc() - '#{config.CLEANUP.TASK_HISTORY_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.info("Deleted #{count} rows from task history")


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
    logger.info("Deleted #{count} rows from current subtasks")


deleteMarkers = () ->
  tables.deletes.combined()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_MARKER_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.info("Deleted #{count} rows from delete marker table")


deleteParcels = () ->
  tables.deletes.parcel()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_PARCEL_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.info("Deleted #{count} rows from delete parcels table")


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
  count = 0

  Promise.map subtask.data.values, (key) -> Promise.try () ->
    logger.spawn(subtask.name).debug () -> "deleting: photo with key: #{key}"

    awsService.deleteObject
      extAcctName: config.EXT_AWS_PHOTO_ACCOUNT
      Key: key
    .then () ->
      logger.spawn(subtask.name).debug () -> 'successful deletion of aws photo ' + key
      count++
      tables.deletes.photos()
      .where {key}
      .del()
      .catch (error) ->
        throw new jobQueueErrors.SoftFail(error, "Transient Photo Deletion error; try again later. Failed to delete from database.")
    .catch (error) ->
      throw new jobQueueErrors.SoftFail(error, "Transient AWS Photo Deletion error; try again later")
  .then () ->
    logger.info("Deleted #{count} photos from AWS")

deleteSessionSecurities = (subtask) ->
  tables.auth.sessionSecurity()
  .whereNotExists () ->
    @select(1).from(tables.auth.session.tableName)
    .where(sid: "#{tables.auth.sessionSecurity.tableName}.session_id")
  .returning('session_id')
  .delete()
  .then (sessionIds) ->
    logger.info("session securities deleted due to missing session: #{sessionIds.length}")
    logger.spawn(subtask.name).debug () -> "sessionIds of session securities deleted: #{JSON.stringify(sessionIds, null, 2)}"

deleteRequestErrors = (subtask) ->
  tables.history.requestError()
  .where(unexpected: false)
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.REQUEST_ERROR_EXPECTED_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.info("Deleted #{count} expected error entries from request error history")
    tables.history.requestError()
    .where(handled: true)
    .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.REQUEST_ERROR_HANDLED_DAYS} days'::INTERVAL")
    .delete()
  .then (count) ->
    logger.info("Deleted #{count} handled error entries from request error history")
    tables.history.requestError()
    .where(unexpected: true)
    .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.REQUEST_ERROR_UNEXPECTED_DAYS} days'::INTERVAL")
    .delete()
  .then (count) ->
    logger.info("Deleted #{count} unexpected error entries from request error history")



module.exports = new TaskImplementation 'cleanup', {
  rawTables
  subtaskErrors
  taskHistory
  currentSubtasks
  deleteMarkers
  deleteParcels
  deletePhotosPrep
  deletePhotos
  deleteSessionSecurities
  deleteRequestErrors
}
