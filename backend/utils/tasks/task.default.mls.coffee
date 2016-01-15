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


NUM_ROWS_TO_PAGINATE = 5000


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

finalizeDataPrep = (subtask) ->
  tables.property.listing()
  .select('rm_property_id')
  .where(batch_id: subtask.batch_id)
  .then (ids) ->
    ids = _.uniq(_.pluck(ids, 'rm_property_id'))
    jobQueue.queueSubsequentPaginatedSubtask(null, subtask, ids, NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_finalizeData")

finalizeData = (subtask) ->
  Promise.map subtask.data.values, mlsHelpers.finalizeData.bind(null, subtask)


module.exports = new TaskImplementation
  loadRawData: loadRawData
  normalizeData: normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts
  finalizeDataPrep: finalizeDataPrep
  finalizeData: finalizeData
  activateNewData: dataLoadHelpers.activateNewData
