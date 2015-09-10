Promise = require 'bluebird'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../util.jobQueue'
tables = require '../../config/tables'
logger = require '../../config/logger'
sqlHelpers = require '../util.sql.helpers'
mlsHelpers = require './util.mlsHelpers'
TaskImplementation = require './util.taskImplementation'
_ = require 'lodash'


# NOTE: This file a default task definition used for MLSs that have no special cases


NUM_ROWS_TO_PAGINATE = 500


loadRawData = (subtask) ->
  mlsHelpers.loadUpdates subtask,
    dataSourceId: subtask.task_name
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask null, subtask, numRows, NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_normalizeData",
      type: 'listing'
      rawTableSuffix: 'listing'

normalizeData = (subtask) ->
  dataLoadHelpers.normalizeData subtask,
    rawTableSuffix: subtask.data.rawTableSuffix
    dataSourceId: subtask.task_name
    dataSourceType: 'mls'
    updateRecord: mlsHelpers.updateRecord

finalizeDataPrep = (subtask) ->
  tables.propertyData.listing()
  .distinct('rm_property_id')
  .select()
  .where(batch_id: subtask.batch_id)
  .whereNull('deleted')
  .where(hide_listing: false)
  .then (ids) ->
    jobQueue.queueSubsequentPaginatedSubtask(null, subtask, _.pluck(ids, 'rm_property_id'), NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_finalizeData")

finalizeData = (subtask) ->
  Promise.map subtask.data.values, mlsHelpers.finalizeData.bind(null, subtask)


module.exports = new TaskImplementation
  loadRawData: loadRawData
  normalizeData: normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts.bind(null, 'listing', tables.propertyData.listing)
  finalizeDataPrep: finalizeDataPrep
  finalizeData: finalizeData
  activateNewData: dataLoadHelpers.activateNewData
