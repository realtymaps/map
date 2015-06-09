mlsHelpers = require '../util.mlsHelpers'
taskHelpers = require './util.taskHelpers'
jobQueue = require '../util.jobQueue'


loadDataRawMain = (subtask) ->
  mlsHelpers.loadRetsTableUpdates subtask,
    rawTableSuffix: 'main'
    retsDbName: 'Property'
    retsTableName: 'RES'
    retsQueryTemplate: "[(LastChangeTimestamp=]YYYY-MM-DD[T]HH:mm:ss[+)]"
    retsId: 'swflmls'
  .then (numRows) ->
    jobQueue.queueSubsequentPaginatedSubtask(jobQueue.knex, subtask, numRows, 20, 'normalizeData')

normalizeData = (subtask) ->
  mlsHelpers.normalizeData subtask,
    rawTableSuffix: 'main'
    dataSourceId: 'swflmls'

#finalizeDataPrep = (subtask) ->


subtasks =
  loadDataRawMain: loadDataRawMain
  normalizeData: normalizeData
  recordChangeCounts: mlsHelpers.recordChangeCounts
  #finalizeDataPrep: finalizeDataPrep
  #finalizeData: finalizeData
  #removeExtraRows: removeExtraRows

module.exports =
  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtasks[subtask.name](subtask)
