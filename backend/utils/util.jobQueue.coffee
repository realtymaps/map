fpath = require 'path'
loaders = require './util.loaders'
dbs = require '../config/dbs'
Promise = require 'bluebird'
sqlHelpers = require './util.sql.helpers'
logger = require '../config/logger'
analyzeValue = require '../../common/utils/util.analyzeValue'
_ = require 'lodash'
{notification} = require 'util.notifications.coffee'


# to understand at a high level most of what is going on in this code and how to write a task to be utilized by this
# module, go to https://realtymaps.atlassian.net/wiki/display/DN/Job+queue%3A+the+developer+guide


SUBTASK_ZOMBIE_SLACK = "INTERVAL '1 minute'"

sendNotification = notification("jobQueue")
knex = dbs.users.knex

tables =
  taskConfig: 'jq_task_config'
  subtaskConfig: 'jq_subtask_config'
  queueConfig: 'jq_queue_config'
  taskHistory: 'jq_task_history'
  currentSubtasks: 'jq_current_subtasks'
  subtaskErrorHistory: 'jq_subtask_error_history'

class SoftFail extends Error
  constructor: (@message) ->
    @name = 'SoftFail'

class HardFail extends Error
  constructor: (@message) ->
    @name = 'HardFail'


withSchedulingLock = (handler) ->
  knex.transaction (transaction) ->
    transaction.select(knex.raw("pg_advisory_xact_lock(jq_lock_key(), 0)"))
    .then () ->
      return handler(transaction)

queueReadyTasks = (transaction) -> Promise.try () ->
  batchId = (Date.now()).toString(36)
  overrideRunNames = []
  overrideSkipNames = []
  readyPromises = []
  # load all task definitions to check for overridden "ready" method
  taskImpls = loaders.loadSubmodules(path.join(__dirname, 'tasks'), /^task\.(\w+)\.coffee$/)
  for taskName, taskImpl of taskImpls
    # task might define its own logic for determining if it should run
    if taskImpl.ready?
      readyPromise = taskImpl.ready(transaction)
      .then (override) ->
        # if the result is true, run this task (as long as it is active and is past any ignore_until)
        if override == true
          overrideRunNames.push(taskName)
        # if the result is false, /don't/ run this task (no matter what)
        else if override == false
          overrideSkipNames.push(taskName)
        # otherwise, rely on default ready-checking logic
      readyPromises.push(readyPromise)
  Promise.all(readyPromises)
  .then () ->
    transaction.select()
    .from(tables.taskConfig)
    .where(active: true)                  # only consider active tasks
    .whereRaw("COALESCE(ignore_until, '1970-01-01'::TIMESTAMP) <= NOW()") # only consider tasks whose time has come
    .where () ->
      sqlHelpers.whereIn(this, 'name', overrideRunNames)        # run if in the override run list ...
      sqlHelpers.orWhereNotIn(this, 'name', overrideSkipNames)  # ... or it's not in the override skip list ...
      .whereNotExists () ->                                     # ... and we can't find a history entry such that ...
        this.select()
        .from(tables.taskHistory)
        .whereRaw("#{tables.taskConfig}.name = #{tables.taskHistory}.name")
        .where () ->
          this
          .whereNull("#{tables.taskConfig}.repeat_period_minutes")   # ... it isn't set to repeat ... 
          .orWhereIn("status", ['running', 'preparing'])             # ... or it's currently running or preparing to run ...
          .orWhereRaw("started + #{tables.taskConfig}.repeat_period_minutes * INTERVAL '1 minute' > NOW()")  # ... or it hasn't passed its repeat delay
  .then (readyTasks=[]) ->
    Promise.map readyTasks, (task) ->
      queueTask(transaction, batchId, task, '<scheduler>')

queueTask = (transaction, batchId, task, initiator) -> Promise.try () ->
  transaction.table(tables.taskHistory)
  .where(name: task.name)
  .update(current: false)  # only the most recent entry in the history should be marked current
  .then () ->
    transaction.table(tables.taskHistory)
    .insert
      name: task.name
      data: task.data
      batch_id: batchId
      initiator: initiator
      warn_timeout_minutes: task.warn_timeout_minutes
      kill_timeout_minutes: task.kill_timeout_minutes
  .then () -> # clear out any subtasks for prior runs of this task
    knex.table(tables.currentSubtasks)
    .where(task_name: task.name)
    .delete()
  .then () ->  # now to enqueue (initial) subtasks
    # see if the task wants to specify the subtasks to run (vs using static config)
    taskImpl = require("./tasks/task.#{task.name}")
    subtaskOverridesPromise = taskImpl.prepSubtasks?(transaction, batchId, task.data) || false
    subtaskConfigPromise = transaction.table(tables.subtaskConfig)
    .where(task_name: task.name)
    .then (subtaskConfig=[]) ->
      subtaskConfig
    Promise.props
      subtaskOverrides: subtaskOverridesPromise
      subtaskConfig: subtaskConfigPromise
  .then (subtaskInfo) ->
    if typeof(subtaskInfo.subtaskOverrides) == 'number'   # subtasks already enqueued by custom logic, count returned
      return subtaskInfo.subtaskOverrides
    else if subtaskInfo.subtaskOverrides == false  # use config-based values for all subtasks and data
      return queueSubtasks(transaction, batchId, task.data, subtaskInfo.subtaskConfig)
    else  # handle on a case-by-case basis
      subtasks = []
      subtaskCount = 0
      subtaskHash = _.indexBy(subtaskInfo.subtaskConfig, 'name')
      for name, data of subtaskInfo.subtaskOverrides
        if typeof(data) == 'number'  # this subtask already enqueued by task logic, count given
          subtaskCount += data
        else if data == false  # use config static values for this subtask
          subtasks.push(subtaskHash[name])
        else  # this subtask's data was overridden by task logic
          subtaskHash[name].data = data
          subtasks.push(subtaskHash[name])
      return queueSubtasks(transaction, batchId, task.data, subtasks)
      .then (count) ->
        return subtaskCount+count  # add up the counts from overridden and config-based subtasks
  .then (count) ->
    transaction.table(tables.taskHistory)
    .where
      name: task.name
      current: true
    .update
      subtasks_created: count
      status: 'running'
      status_changed: knex.raw('NOW()')

queueSubtasks = (transaction, batchId, _taskData, subtasks) ->
  Promise.try () ->
    if _taskData != undefined || !subtasks?.length
      return _taskData
    transaction.table(tables.taskHistory)
    .where(current: true, name: subtasks[0].task_name)
  .then (task) ->
    task?[0]?.data
  .then (taskData) ->
    Promise.all _.map(subtasks, queueSubtask.bind(null, transaction, batchId, taskData))
  .then (counts) ->
    return _.reduce counts, (sum, count) -> sum+count

queueSubtask = (transaction, batchId, _taskData, subtask) ->
  Promise.try () ->
    if _taskData != undefined
      return _taskData
    transaction.table(tables.taskHistory)
    .where(current: true, name: subtask.task_name)
  .then (task) ->
    task?[0]?.data
  .then (taskData) ->
    if _.isArray subtask.data    # an array for data means to create multiple subtasks, one for each element of data
      Promise.map subtask.data, (data) ->
        singleSubtask = _.clone(subtask)
        singleSubtask.data = data
        singleSubtask.task_data = taskData
        singleSubtask.task_step = "#{subtask.task_name}_#{subtask.step_num||'FINAL'}"  # this is needed by a stored proc
        singleSubtask.batch_id = batchId
        transaction.table(tables.currentSubtasks)
        .insert singleSubtask
      .then () ->
        return subtask.data.length
    else
      singleSubtask = _.clone(subtask)
      singleSubtask.task_data = taskData
      singleSubtask.task_step = "#{subtask.task_name}_#{subtask.step_num||'FINAL'}"  # this is needed by a stored proc
      singleSubtask.batch_id = batchId
      transaction.table(tables.currentSubtasks)
      .insert singleSubtask
      .then () ->
        return 1

cancelTask = (taskName, status) ->
  # note that this doesn't cancel subtasks that are already running; there's no easy way to do that except within the
  # worker that's executing that subtask, and we're not going to make that work poll to watch for a cancel message
  knex.table(tables.taskHistory)
  .where
    name: taskName
    current: true
  .whereNull('finished')
  .update
    status: status
    status_changed: knex.raw('NOW()')
  .then () ->
    knex.table(tables.currentSubtasks)
    .where
      task_name: taskName
      status: 'queued'
    .update
      status: 'canceled'
      finished: knex.raw('NOW()')

executeSubtask = (subtask) ->
  knex.table(tables.currentSubtasks)
  .where(id: subtask.id)
  .update
    status: 'running'
    started: knex.raw('NOW()')
  .then () ->
    taskImpl = require("./tasks/task.#{subtask.task_name}")
    subtaskPromise = taskImpl.executeSubtask(subtask)
    .then () ->
      knex.table(tables.currentSubtasks)
      .where(id: subtask.id)
      .update
        status: 'success'
        finished: knex.raw('NOW()')
    if subtask.kill_timeout_seconds?
      subtaskPromise = subtaskPromise
      .timeout(subtask.kill_timeout_seconds*1000)
      .catch Promise.TimeoutError, _handleSubtaskError.bind(null, subtask, 'timeout', subtask.hard_fail_timeouts, 'timeout')
    subtaskPromise = subtaskPromise
    .catch SoftFail, _handleSubtaskError.bind(null, subtask, 'soft fail', false)
    .catch HardFail, _handleSubtaskError.bind(null, subtask, 'hard fail', true)
    .catch _handleSubtaskError.bind(null, subtask, 'infrastructure fail', true)
    .catch (err) -> # if we make it here, then we probably can't rely on the db for error reporting
      sendNotification
        subject: 'major db interaction problem'
        subtask: subtask
        error: err
      throw err
    if subtask.warn_timeout_seconds?
      warnTimeout = setTimeout () ->
        sendNotification
          subject: 'subtask: long run warning'
          subtask: subtask
          error: "subtask has been running for longer than #{subtask.warn_timeout_seconds} seconds"
      subtaskPromise = subtaskPromise
      .finally () ->
        clearTimeout(warnTimeout)
    return subtaskPromise

_handleSubtaskError = (subtask, status, hard, error) ->
  Promise.try () ->
    if !hard
      if subtask.retry_max_count? && subtask.retry_max_count >= subtask.retry_num
        if subtask.hard_fail_after_retries
          hard = true
          status = 'hard fail'
          error = "max retries exceeded: #{error}"
      else
        retrySubtask = _.omit(subtask, 'id', 'enqueued', 'started')
        retrySubtask.retry_num++
        retrySubtask.ignore_until = knex.raw("NOW() + ? * INTERVAL '1 second'", [subtask.retry_delay_seconds])
        knex.table(tables.currentSubtasks)
        .insert retrySubtask
  .then () ->
    knex.table(tables.currentSubtasks)
    .where(id: subtask.id)
    .update
      status: status
      finished: knex.raw('NOW()')
  .then () ->
    knex.table(tables.currentSubtasks)
    .where(id: subtask.id)
  .then (updatedSubtask) ->
    updatedSubtask[0].error = "subtask: #{error}"
    knex.table(tables.subtaskErrorHistory)
    .insert updatedSubtask[0]
  .then () ->
    if hard
      Promise.join cancelTask(subtask.task_name, 'hard fail'), sendNotification
        subject: 'subtask: hard fail'
        subtask: subtask
        error: "subtask: #{error}"
    throw error

# should this be rewritten to use a transaction and query built by knex?  I decided to implement it as a stored proc
# in order to enforce the locking semantics, but I'm not sure if that's really a good reason
getQueuedSubtask = (queue_name) ->
  knex.select('*').from(knex.raw('jq_get_next_subtask(?)', [queue_name]))   
  .then (results) ->
    if !results?[0]?.id?
      return null
    else
      return results[0]

_sendLongTaskWarnings = () ->
  # warn about long-running tasks
  knex.table(tables.taskHistory)
  .whereNull('finished')
  .whereNotNull('warn_timeout_minutes')
  .where(current: true)
  .whereRaw("started + warn_timeout_minutes * INTERVAL '1 minute' < NOW()")
  .then (tasks=[]) ->
    sendNotification
      subject: 'task: long run warning'
      tasks: tasks
      error: "tasks have been running for longer than expected"

_killLongTasks = () ->
  # kill long-running tasks
  knex.table(tables.taskHistory)
  .whereNull('finished')
  .whereNotNull('kill_timeout_minutes')
  .where(current: true)
  .whereRaw("started + kill_timeout_minutes * INTERVAL '1 minute' < NOW()")
  .then (tasks=[]) ->
    cancelPromise = Promise.map tasks, (task) ->
      cancelTask(task.name, 'timeout')
    notificationPromise = sendNotification
      subject: 'task: long run killed'
      tasks: tasks
      error: "tasks have been running for longer than expected"
    Promise.join cancelPromise, notificationPromise

_handleZombies = () ->
  # mark subtasks that should have been suicidal (but maybe disappeared instead) as zombies, and possibly cancel their tasks 
  knex.table(tables.currentSubtasks)
  .whereNull('finished')
  .whereNotNull('started')
  .whereNotNull('kill_timeout_seconds')
  .whereRaw("started + #{SUBTASK_ZOMBIE_SLACK} + kill_timeout_seconds * INTERVAL '1 second' < NOW()")
  .then (subtasks=[]) ->
    Promise.map subtasks, (subtask) ->
      _handleSubtaskError(subtask, 'zombie', subtask.hard_fail_zombies, 'zombie')

_handleSuccessfulTasks = () ->
  # mark running tasks with no unfinished or error subtasks as successful
  knex.table(tables.taskHistory)
  .where(status: 'running')
  .whereNotExists () ->
    this.table(tables.currentSubtasks)
    .whereRaw("#{tables.currentSubtasks}.task_name = #{tables.taskHistory}.name")
    .where () ->
      this
      .whereNull('finished')
      .orWhereIn('status', ['hard fail', 'infrastructure fail', 'canceled'])
      .orWhere
        status: 'timeout'
        hard_fail_timeouts: true
      .orWhere
        status: 'zombie'
        hard_fail_zombies: true
  .update
    status: 'success'
    status_changed: knex.raw('NOW()')

_setFinishedTimestamps = () ->
  # set the correct 'finished' value for tasks based on finished timestamps for their subtasks
  knex.table(tables.currentSubtasks)
  .select('task_name', knex.raw('MAX(finished) AS finished'))
  .groupBy('task_name')
  .then (tasks=[]) ->
    Promise.map tasks, (task) ->
      knex.table(tables.taskHistory)
      .where
        current: true
        name: task.task_name
      .whereNotIn('status', ['preparing', 'running'])
      .update(finished: task.finished)

doMaintenance = () ->
  Promise.try () ->
    _sendLongTaskWarnings()
  .then () ->
    _killLongTasks()
  .then () ->
    _handleZombies()
  .then () ->
    _handleSuccessfulTasks()
  .then () ->
    _setFinishedTimestamps()
    
updateTaskCounts = () ->
  knex.select(knex.raw('jq_update_task_counts()'))

# sendNotification = (options) ->
#   # this is a placeholder...  we need to decide what we want this to do, and implement it.
#   # since this will often happen outside the webserver (in scheduled tasks), we probably want to send emails with full
#   # details and SMS with abbreviated summaries to db-configured emails and SMS numbers (though note that these values
#   # should be loaded at startup and cached, since we don't want db problems to stop notifications about those problems)
#   Promise.resolve()

getQueueNeeds = () ->
  knex.select('*').from(knex.raw('jq_get_queue_needs()'))
  .then (needs) ->
    needs || []


module.exports =
  withSchedulingLock: withSchedulingLock
  queueReadyTasks: queueReadyTasks
  queueTask: queueTask
  queueSubtasks: queueSubtasks
  queueSubtask: queueSubtask
  cancelTask: cancelTask
  executeSubtask: executeSubtask
  getQueuedSubtask: getQueuedSubtask
  doMaintenance: doMaintenance
  sendNotification: sendNotification
  updateTaskCounts: updateTaskCounts
  getQueueNeeds: getQueueNeeds
  SoftFail: SoftFail
  HardFail: HardFail
  tables: tables
  knex: knex
