Promise = require('bluebird')
tables = require('../config/tables')
logger = require('../config/logger').spawn('task:cleanup')
config = require('../config/config')
dbs = require('../config/dbs')
TaskImplementation = require('./util.taskImplementation')
jobQueue = require('../services/service.jobQueue')
mlsHelpers = require('./util.mlsHelpers')
_ = require('lodash')
internals = require './task.cleanup.internals'


### eslint-disable ###
rawTables = (subtask) ->
  ### eslint-enable ###
  logger.debug -> 'Begin cleaning and dropping raw tables'

  Promise.join(internals.cleanRawTables(), internals.dropRawTables())
  .then () ->
    logger.debug -> 'done cleaning and dropping raw tables'


### eslint-disable ###
subtaskErrors = (subtask) ->
  ### eslint-enable ###
  tables.jobQueue.subtaskErrorHistory()
  .whereRaw("finished < now_utc() - '#{config.CLEANUP.SUBTASK_ERROR_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from subtask error history"


### eslint-disable ###
taskHistory = (subtask) ->
  ### eslint-enable ###
  tables.jobQueue.taskHistory()
  .where(current: false)
  .whereRaw("started < now_utc() - '#{config.CLEANUP.TASK_HISTORY_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from task history"


### eslint-disable ###
currentSubtasks = (subtask) ->
  ### eslint-enable ###
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


### eslint-disable ###
deleteMarkers = (subtask) ->
  ### eslint-enable ###
  tables.deletes.combined()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_MARKER_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from delete marker table"


### eslint-disable ###
deleteParcels = (subtask) ->
  ### eslint-enable ###
  tables.deletes.parcel()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_PARCEL_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from delete parcels table"


### eslint-disable ###
deleteInactiveRows = (subtask) ->
  ### eslint-enable ###
  tables.finalized.combined()
  .where(active: false)
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.INACTIVE_ROW_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug () -> "Deleted #{count} rows from combined data table"


### eslint-disable ###
deletePhotosPrep = (subtask) ->
  ### eslint-enable ###
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

  Promise.map subtask.data.values, (key) ->
    mlsHelpers.deleteOldPhoto(subtask, key)


module.exports = new TaskImplementation 'cleanup', {
  rawTables
  subtaskErrors
  taskHistory
  currentSubtasks
  deleteMarkers
  deleteParcels
  deleteInactiveRows
  deletePhotosPrep
  deletePhotos
}
