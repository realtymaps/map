retsHelpers = require './util.retsHelpers'


subtasks =
  loadDataRawMain: (subtask) ->
    retsHelpers.loadRetsTableUpdates subtask,
      rawTableSuffix: 'main'
      retsDbName: 'Property'
      retsTableName: 'RES'
      retsQueryTemplate: "[(LastChangeTimestamp=]YYYY-MM-DD[T]HH:mm:ss[+)]"
      retsId: 'swflmls'
    
module.exports =
  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtasks[subtask.name](subtask)
