Promise = require "bluebird"
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../util.jobQueue'
tables = require '../../config/tables'
logger = require '../../config/logger'
sqlHelpers = require '../util.sql.helpers'
coreLogicHelpers = require './util.coreLogicHelpers'
encryptor = require '../../config/encryptor'
PromiseFtp = require '../util.promiseFtp'


NUM_ROWS_TO_PAGINATE = 500


checkFtpDrop = (subtask) ->
  ftp = new PromiseFtp()
  ftp.connect
    host: subtask.task_data.host
    user: subtask.task_data.user
    password: encryptor.decrypt(subtask.task_data.password)
  .then (msg) ->
    logger.debug("FTP message: #{msg}")
    ftp.list('/')
  .then ()

loadRawData = (subtask) ->
  coreLogicHelpers.loadUpdates subtask,
    rawTableSuffix: 'main'
    dataSourceId: subtask.task_name
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


subtasks =
  loadRawData: loadRawData
  normalizeData: normalizeData
  recordChangeCounts: dataLoadHelpers.recordChangeCounts.bind(null, 'main', tables.propertyData.mls)
  finalizeDataPrep: finalizeDataPrep
  finalizeData: finalizeData
  activateNewData: dataLoadHelpers.activateNewData
  checkFtpDrop: checkFtpDrop

module.exports =
  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtasks[subtask.name.replace(/[^_]+_/g,'')](subtask)
