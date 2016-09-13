tables = require '../config/tables'
{TaskNotImplemented} = require '../utils/errors/util.error.jobQueue'
Promise = require 'bluebird'
require '../config/promisify'
memoize = require 'memoizee'
mlsConfigService = null
errors = require '../utils/errors/util.errors.task'
_ = require 'lodash'


# static function that takes a task name and returns a promise resolving to either the task's implementation module, or
# if it can't find one and there is an MLS config with the task name as its id, then use the default MLS (or MLS photos) implementation
_getTaskCode = (taskName) ->
  if !mlsConfigService
    mlsConfigService = require '../services/service.mls_config'
  Promise.try () ->
    try
      return Promise.resolve(require("./task.#{taskName}"))
    catch err
      baseName = taskName.replace('_photos', '')
      mlsConfigService.getByIdCached(baseName)
      .then (mlsConfig) ->
        if mlsConfig?
          if taskName.indexOf('_photos') == -1
            return require("./task.default.mls")(taskName)
          else
            return require("./task.default.photos")(taskName)
        throw new TaskNotImplemented(err, "can't find code for task with name: #{taskName}")

class TaskImplementation

  constructor: (@taskName, @subtasks, ready) ->
    @name = 'TaskImplementation'
    if ready
      @ready = ready

  executeSubtask: (subtask) -> Promise.try () =>
    # call the handler for the subtask
    if !subtask.name?
      throw new errors.TaskNameError('subtask.name must be defined')
    if subtask.name.indexOf(@taskName+'_') != 0
      throw new errors.TaskNameError("Subtask name does not match format taskname_subtaskname: #{subtask.name}.")
    subtaskBaseName = subtask.name.substring(@taskName.length+1)  # subtask name format is: taskname_subtaskname (in the database)
    if !(subtaskBaseName of @subtasks)
      throw new errors.MissingSubtaskError("Can't find subtask code for: #{subtask.name}; subtasks available: #{Object.keys(@subtasks).join(',')}")
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

  ready: () -> true


TaskImplementation.getTaskCode = memoize.promise(_getTaskCode, primitive: true)


module.exports = TaskImplementation
