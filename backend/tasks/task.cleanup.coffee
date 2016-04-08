Promise = require 'bluebird'
tables = require '../config/tables'
logger = require '../config/logger'
config = require '../config/config'
dbs = require '../config/dbs'
TaskImplementation = require './util.taskImplementation'
jobQueue = require '../utils/util.jobQueue'
mlsHelpers = require './util.mlsHelpers'

# NOTE: This file a default task definition used for MLSs that have no special cases
NUM_ROWS_TO_PAGINATE = 2500


rawTables = (subtask) ->
  tables.jobQueue.dataLoadHistory()
  .select('raw_table_name')
  .where(cleaned: false)
  .whereNotNull('raw_table_name')
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_TABLE_DAYS} days'::INTERVAL")
  .map (loadEntry) ->
    logger.debug("cleaning up old raw table: #{loadEntry.raw_table_name}")

    dbs.get('raw_temp').schema.dropTableIfExists(loadEntry.raw_table_name)
    .then () ->
      tables.jobQueue.dataLoadHistory()
      .where(raw_table_name: loadEntry.raw_table_name)
      .update(cleaned: true)

subtaskErrors = (subtask) ->
  tables.jobQueue.subtaskErrorHistory()
  .whereRaw("finished < now_utc() - '#{config.CLEANUP.SUBTASK_ERROR_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug "Deleted #{count} rows from subtask error history"

deleteMarkers = (subtask) ->
  tables.deletes.property()
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.OLD_DELETE_MARKER_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug "Deleted #{count} rows from delete marker table"

deleteInactiveRows = (subtask) ->
  tables.property.combined()
  .where(active: false)
  .whereRaw("rm_inserted_time < now_utc() - '#{config.CLEANUP.INACTIVE_ROW_DAYS} days'::INTERVAL")
  .delete()
  .then (count) ->
    logger.debug "Deleted #{count} rows from combined data table"

deletePhotosPrep = (subtask) ->
  tables.deletes.photos()
  .select('id')
  .where(batch_id: subtask.batch_id)
  .orderBy 'id'
  .then (ids) ->
    jobQueue.queueSubsequentPaginatedSubtask({subtask, totalOrList: ids, maxPage: NUM_ROWS_TO_PAGINATE, laterSubtaskName: "deletePhotos"})

deletePhotos = (subtask) ->
  Promise.map subtask.data.values, mlsHelpers.deleteOldPhoto.bind(null, subtask)


module.exports = new TaskImplementation {
  rawTables
  subtaskErrors
  deleteMarkers
  deleteInactiveRows
  deletePhotosPrep
  deletePhotos
}
