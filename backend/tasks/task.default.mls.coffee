Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../utils/util.jobQueue'
tables = require '../config/tables'
logger = require '../config/logger'
mlsHelpers = require './util.mlsHelpers'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'

# NOTE: This file a default task definition used for MLSs that have no special cases
NUM_ROWS_TO_PAGINATE = 2500


loadRawData = (subtask) ->
  mlsHelpers.loadUpdates subtask,
    dataSourceId: subtask.task_name
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask null, subtask, numRows, NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_normalizeData",
      dataType: 'listing'

normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    dataSourceId: subtask.task_name
    dataSourceType: 'mls'
    buildRecord: mlsHelpers.buildRecord

_getUniqueRmIds = (subtask, dbFn) ->
  dbFn()
  .select('rm_property_id')
  .where(batch_id: subtask.batch_id)
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))

finalizeDataPrep = (subtask) ->
  _getUniqueRmIds(subtask, tables.property.listing)
  .then (ids) ->
    jobQueue.queueSubsequentPaginatedSubtask(null, subtask, ids,
      NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_finalizeData")

finalizeData = (subtask) ->
  Promise.map subtask.data.values, mlsHelpers.finalizeData.bind(null, subtask)

storePhotosPrep = (subtask) ->
  _getUniqueRmIds(subtask, tables.property.combined)
  .then (ids) ->
    jobQueue.queueSubsequentPaginatedSubtask(null, subtask, ids,
      NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_storePhotos")

storePhotos = (subtask) ->
  Promise.map subtask.data.values, mlsHelpers.storePhotos.bind(null, subtask)

deletePhotosPrep = (subtask) ->
  tables.deletes.photo()
  .select('id')
  .where(batch_id: subtask.batch_id)
  .orderBy 'id'
  .then (ids) ->
    jobQueue.queueSubsequentPaginatedSubtask(null, subtask, ids,
      NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_deletePhotos")

deletePhotos = (subtask) ->
  Promise.map subtask.data.values, mlsHelpers.deleteOldPhoto.bind(null, subtask)

module.exports = new TaskImplementation {
  loadRawData
  normalizeData
  finalizeDataPrep
  finalizeData
  storePhotosPrep
  storePhotos
  deletePhotosPrep
  deletePhotos
  activateNewData: dataLoadHelpers.activateNewData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
}
