mlsHelpers = require '../util.mlsHelpers'
taskHelpers = require './util.taskHelpers'
jobQueue = require '../util.jobQueue'


loadDataRawMain = (subtask) ->
  updatesPromise = mlsHelpers.loadRetsTableUpdates subtask,
    rawTableSuffix: 'main'
    retsDbName: 'Property'
    retsTableName: 'RES'
    retsQueryTemplate: "[(LastChangeTimestamp=]YYYY-MM-DD[T]HH:mm:ss[+)]"
    retsId: 'swflmls'
  nextSubtaskPromise = jobQueue.getSubtaskConfig(jobQueue.knex, 'normalizeData', subtask.task_name)
  Promise.join(updatesPromise, nextSubtaskPromise)
  .then (numRows, nextSubtask) ->
    jobQueue.queuePaginatedSubtask(jobQueue.knex, subtask.batch_id, subtask.task_data, numRows, 20, nextSubtask)

normalizeData = (subtask) ->
  mlsHelpers.normalizeData subtask,
    rawTableSuffix: 'main'
    dataSourceId: 'swflmls'

    
subtasks =
  loadDataRawMain: loadDataRawMain
  normalizeData: normalizeData
  markDeleted: mlsHelpers.markOtherRowsDeleted
  #finalizeData: finalizeData
  #removeExtraRows: removeExtraRows

module.exports =
  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtasks[subtask.name](subtask)
