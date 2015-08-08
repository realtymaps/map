Promise = require 'bluebird'
encryptor = require '../../config/encryptor'
jobQueue = require '../util.jobQueue'
_ = require 'lodash'
tables = require '../../config/tables'
logger = require '../../config/logger'
sqlHelpers = require '../util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'
coreLogicHelpers = require './util.coreLogicHelpers'


_getCreds: (subtask) ->
  taskData = JSON.parse subtask.task_data
  for k, val of taskData.DIGIMAPS
    taskData.DIGIMAPS[k] = encryptor.decrypt(val)
  taskData.DIGIMAPS


NUM_ROWS_TO_PAGINATE = 500


loadDataRawMain = (subtask) ->
  coreLogicHelpers.loadUpdates subtask,
    rawTableSuffix: 'main'
    retsId: subtask.task_name
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, numRows, NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_normalizeData")

normalizeData = (subtask) ->
  coreLogicHelpers.normalizeData subtask,
    rawTableSuffix: 'main'
    dataSourceId: subtask.task_name

finalizeDataPrep = (subtask) ->
  query = tables.propertyData.mls()
  sqlHelpers.selectCountDistinct(query, 'rm_property_id')
  .where(batch_id: subtask.batch_id)
  .then (info) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, info[0].count, NUM_ROWS_TO_PAGINATE, "#{subtask.task_name}_finalizeData")

finalizeData = (subtask) ->
  tables.propertyData.mls()
  .distinct('rm_property_id')
  .select()
  .where(batch_id: subtask.batch_id)
  .orderBy('rm_property_id')
  .offset(subtask.data.offset)
  .limit(subtask.data.count)
  .then (ids) ->
    Promise.map ids, coreLogicHelpers.finalizeData.bind(null, subtask)


_subtasks =
  loadDataRawMain: loadDataRawMain
  normalizeData: normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts.bind(null, ['main'], tables.propertyData.tax)
  finalizeDataPrep: finalizeDataPrep
  finalizeData: finalizeData
  activateNewData: dataLoadHelpers.activateNewData
      
module.exports =
  executeSubtask: (subtask) ->
    _subtasks[subtask.name](subtask)
