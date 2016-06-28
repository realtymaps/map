tables = require '../config/tables'
{TaskNotImplemented} = require '../utils/errors/util.error.jobQueue'
Promise = require 'bluebird'
require '../config/promisify'
memoize = require 'memoizee'
mlsConfigService = null
errors = require '../utils/errors/util.errors.task'


# static function that takes a task name and returns a promise resolving to either the task's implementation module, or
# if it can't find one and there is an MLS config with the task name as its id, then use the default MLS implementation
_getTaskCode = (taskName) ->
  if !mlsConfigService
    mlsConfigService = require '../services/service.mls_config'
  Promise.try () ->
    try
      return Promise.resolve(require("./task.#{taskName}"))
    catch err
      mlsConfigService.getByIdCached(taskName)
      .then (mlsConfig) ->
        if mlsConfig?
          return require("./task.default.mls")(taskName)
        throw new TaskNotImplemented(err, "can't find code for task with name: #{taskName}")


class TaskImplementation

  constructor: (@taskName, @subtasks, @ready) ->
    @name = 'TaskImplementation'

  executeSubtask: (subtask) -> Promise.try () =>
    # call the handler for the subtask
    if !subtask.name?
      throw new errors.TaskNameError('subtask.name must be defined')
    if subtask.name.indexOf(@taskName+'_') != 0
      throw new errors.TaskNameError("Task name is not contained in subtask name. Where the valid format is taskname_subtaskname. For subtask: #{subtask.name}.")
    subtaskBaseName = subtask.name.substring(@taskName.length+1)  # subtask name format is: taskname_subtaskname (in the database)
    if !(subtaskBaseName of @subtasks)
      throw new errors.MissingSubtaskError("Can't find subtask code for #{subtask.name}, subtasks: #{Object.keys(@subtasks).join(',')} aval!!")
    @subtasks[subtaskBaseName](subtask)

  initialize: (transaction, batchId) -> Promise.try () =>
    tables.jobQueue.subtaskConfig(transaction: transaction)
    .where
      task_name: @taskName
      auto_enqueue: true
      active: true
    .then (subtasks) ->
      if !subtasks.length
        return 0
      require('../services/service.jobQueue').queueSubtasks({transaction, batchId, subtasks})
    .then (count) ->
      if count == 0
        throw new Error("0 subtasks enqueued for #{@taskName}")
      count

  ready: null  # to properly set prototype


TaskImplementation.getTaskCode = memoize.promise(_getTaskCode, primitive: true)


module.exports = TaskImplementation
