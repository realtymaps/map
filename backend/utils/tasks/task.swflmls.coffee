mlsHelpers = require '../util.mlsHelpers'
taskHelpers = require './util.taskHelpers'
jobQueue = require '../util.jobQueue'
dbs = require '../../config/dbs'


NUM_ROWS_TO_PAGINATE = 30


loadDataRawMain = (subtask) ->
  mlsHelpers.loadRetsTableUpdates subtask,
    rawTableSuffix: 'main'
    retsDbName: 'Property'
    retsTableName: 'RES'
    retsQueryTemplate: "[(LastChangeTimestamp=]YYYY-MM-DD[T]HH:mm:ss[+)]"
    retsId: 'swflmls'
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, numRows, NUM_ROWS_TO_PAGINATE, 'normalizeData')

normalizeData = (subtask) ->
  mlsHelpers.normalizeData subtask,
    rawTableSuffix: 'main'
    dataSourceId: 'swflmls'

finalizeDataPrep = (subtask) ->
  # slightly hackish query needed for count(distinct blah):
  # https://github.com/tgriesser/knex/issues/238
  dbs.properties.knex(taskHelpers.tables.mlsData)
  .select(dbs.properties.knex.raw('count(distinct "rm_property_id")'))
  .where(batch_id: subtask.batch_id)
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, numRows, NUM_ROWS_TO_PAGINATE, 'finalizeData')


subtasks =
  loadDataRawMain: loadDataRawMain
  normalizeData: normalizeData
  recordChangeCounts: mlsHelpers.recordChangeCounts
  finalizeDataPrep: finalizeDataPrep
  #finalizeData: finalizeData
  #removeExtraRows: removeExtraRows

module.exports =
  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtasks[subtask.name](subtask)
