tables = require '../../config/tables'
{PartiallyHandledError} = require '../util.partiallyHandledError'
Promise = require 'bluebird'
memoize = require 'memoizee'


# static function that takes a task name and returns a promise resolving to either the task's implementation module, or
# if it can't find one and there is an MLS config with the task name as its id, then use the default MLS implementation
_getTaskCode = (taskName) ->
  Promise.try () ->
    try
      return Promise.resolve(require("./task.#{taskName}"))
    catch err
      tables.config.mls()
      .where(id: taskName)
      .then (mlsConfigs) ->
        if mlsConfigs?[0]?
          return require("./task.default.mls")
        throw new PartiallyHandledError(err, "can't find code for task with name: #{taskName}")


class TaskImplementation
  
  constructor: (@subtasks) ->
    @name = 'TaskImplementation'

  executeSubtask: (subtask) ->
    # call the handler for the subtask
    subtaskBaseName = subtask.name.replace(/[^_]+_/g,'')
    if !(subtaskBaseName of @subtasks)
      throw new Error("Can't find subtask code for #{subtask.name}")
    @subtasks[subtaskBaseName](subtask)
    
  initialize: (transaction, batchId, task) ->
    tables.jobQueue.subtaskConfig(transaction)
    .where
      task_name: task.name
      auto_enqueue: true
    .then (subtasks) ->
      if !subtasks.length
        return 0
      jobQueue = require '../util.jobQueue'
      jobQueue.queueSubtasks(transaction, batchId, subtasks)


TaskImplementation.getTaskCode = memoize.promise(_getTaskCode, primitive: true)


module.exports = TaskImplementation
