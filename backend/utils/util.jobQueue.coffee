path = require 'path'
loaders = require './util.loaders'
dbs = require '../config/dbs'
Promise = require 'bluebird'
sqlHelpers = require './util.sql.helpers'
logger = require '../config/logger'
analyzeValue = require '../../common/utils/util.analyzeValue'
_ = require 'lodash'
{notification} = require './util.notifications.coffee'
tables = require '../config/tables'
cluster = require 'cluster'


# to understand at a high level most of what is going on in this code and how to write a task to be utilized by this
# module, go to https://realtymaps.atlassian.net/wiki/display/DN/Job+queue%3A+the+developer+guide


SUBTASK_ZOMBIE_SLACK = "INTERVAL '1 minute'"

sendNotification = notification("jobQueue")
knex = dbs.users.knex

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
    tables.jobQueue.taskConfig(transaction)
    .select()
    .where(active: true)                  # only consider active tasks
    .whereRaw("COALESCE(ignore_until, '1970-01-01'::TIMESTAMP) <= NOW()") # only consider tasks whose time has come
    .where () ->
      sqlHelpers.whereIn(this, 'name', overrideRunNames)        # run if in the override run list ...
      sqlHelpers.orWhereNotIn(this, 'name', overrideSkipNames)  # ... or it's not in the override skip list ...
      .whereNotExists () ->                                     # ... and we can't find a history entry such that ...
        tables.jobQueue.taskHistory(this)
        .select()
        .whereRaw("#{tables.jobQueue.taskConfig.tableName}.name = #{tables.jobQueue.taskHistory.tableName}.name")
        .where () ->
          this
          .whereNull("#{tables.jobQueue.taskConfig.tableName}.repeat_period_minutes")   # ... it isn't set to repeat ... 
          .orWhereIn("status", ['running', 'preparing'])             # ... or it's currently running or preparing to run ...
          .orWhereRaw("started + #{tables.jobQueue.taskConfig.tableName}.repeat_period_minutes * INTERVAL '1 minute' > NOW()")  # ... or it hasn't passed its repeat delay
  .then (readyTasks=[]) ->
    Promise.map readyTasks, (task) ->
      queueTask(transaction, batchId, task, '<scheduler>')

queueTask = (transaction, batchId, task, initiator) -> Promise.try () ->
  tables.jobQueue.taskHistory(transaction)
  .where(name: task.name)
  .update(current: false)  # only the most recent entry in the history should be marked current
  .then () ->
    tables.jobQueue.taskHistory(transaction)
    .insert
      name: task.name
      data: task.data
      batch_id: batchId
      initiator: initiator
      warn_timeout_minutes: task.warn_timeout_minutes
      kill_timeout_minutes: task.kill_timeout_minutes
  .then () -> # clear out any subtasks for prior runs of this task
    tables.jobQueue.currentSubtasks()
    .where(task_name: task.name)
    .delete()
  .then () ->  # now to enqueue (initial) subtasks
    # see if the task wants to specify the subtasks to run (vs using static config)
    taskImpl = require("./tasks/task.#{task.name}")
    subtaskOverridesPromise = taskImpl.prepSubtasks?(transaction, batchId, task.data) || false
    subtaskConfigPromise = tables.jobQueue.subtaskConfig(transaction)
    .where
      task_name: task.name
      auto_enqueue: true
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
    tables.jobQueue.taskHistory(transaction)
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
    tables.jobQueue.taskHistory(transaction)
    .where(current: true, name: subtasks[0].task_name)
    .then (task) ->
      task?[0]?.data
  .then (taskData) ->
    Promise.all _.map subtasks, (subtask) -> # can't use bind here because it passes in unwanted params
      queueSubtask(transaction, batchId, taskData, subtask)  
  .then (counts) ->
    return _.reduce counts, (sum, count) -> sum+count

# convenience function to get another subtask config and then enqueue it based on the current subtask 
queueSubsequentSubtask = (transaction, currentSubtask, laterSubtaskName, manualData, replace) ->
  getSubtaskConfig(transaction, laterSubtaskName, currentSubtask.task_name)
  .then (laterSubtask) ->
    queueSubtask(transaction, currentSubtask.batch_id, currentSubtask.task_data, laterSubtask, manualData, replace)

queueSubtask = (transaction, batchId, _taskData, subtask, manualData, replace) ->
  Promise.try () ->
    if _taskData != undefined
      return _taskData
    tables.jobQueue.taskHistory(transaction)
    .where(current: true, name: subtask.task_name)
    .then (task) ->
      task?[0]?.data
  .then (taskData) ->
    if manualData?
      if replace
        subtaskData = manualData
      else
        if _.isArray manualData && _.isArray subtask.data
          throw new Error("array passed as non-replace manualData for subtask with array data: #{subtask.task_name}/#{subtask.name}")
        else if _.isArray manualData
          subtaskData = manualData
          mergeData = subtask.data
        else if _.isArray subtask.data
          subtaskData = subtask.data
          mergeData = manualData
        else
          subtaskData = _.extend(subtask.data||{}, manualData)
    else
      subtaskData = subtask.data
    if _.isArray subtaskData    # an array for data means to create multiple subtasks, one for each element of data
      Promise.map subtaskData, (data) ->
        singleSubtask = _.clone(subtask)
        singleSubtask.data = data
        if mergeData?
          _.extend(singleSubtask.data, mergeData)
        singleSubtask.task_data = taskData
        singleSubtask.task_step = "#{subtask.task_name}_#{subtask.step_num||'FINAL'}"  # this is needed by a stored proc
        singleSubtask.batch_id = batchId
        tables.jobQueue.currentSubtasks(transaction)
        .insert singleSubtask
      .then () ->
        return subtaskData.length
    else
      singleSubtask = _.clone(subtask)
      singleSubtask.data = subtaskData
      singleSubtask.task_data = taskData
      singleSubtask.task_step = "#{subtask.task_name}_#{subtask.step_num||'FINAL'}"  # this is needed by a stored proc
      singleSubtask.batch_id = batchId
      tables.jobQueue.currentSubtasks(transaction)
      .insert singleSubtask
      .then () ->
        return 1

cancelTask = (taskName, status) ->
  # note that this doesn't cancel subtasks that are already running; there's no easy way to do that except within the
  # worker that's executing that subtask, and we're not going to make that worker poll to watch for a cancel message
  tables.jobQueue.taskHistory()
  .where
    name: taskName
    current: true
  .whereNull('finished')
  .update
    status: status
    status_changed: knex.raw('NOW()')
    finished: knex.raw('NOW()')
  .then () ->
    tables.jobQueue.currentSubtasks()
    .where
      task_name: taskName
      status: 'queued'
    .update
      status: 'canceled'
      finished: knex.raw('NOW()')

executeSubtask = (subtask) ->
  tables.jobQueue.currentSubtasks()
  .where(id: subtask.id)
  .update
    status: 'running'
    started: knex.raw('NOW()')
  .then () ->
    taskImpl = require("./tasks/task.#{subtask.task_name}")
    subtaskPromise = taskImpl.executeSubtask(subtask)
    .then () ->
      tables.jobQueue.currentSubtasks()
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
    if hard
      logger.error("Error executing subtask #{subtask.task_name}/#{subtask.name}<#{JSON.stringify(subtask.data)}>: #{error.stack||error}")
    else
      if subtask.retry_max_count? && subtask.retry_max_count >= subtask.retry_num
        if subtask.hard_fail_after_retries
          hard = true
          status = 'hard fail'
          error = "max retries exceeded: #{error}"
      else
        retrySubtask = _.omit(subtask, 'id', 'enqueued', 'started')
        retrySubtask.retry_num++
        retrySubtask.ignore_until = knex.raw("NOW() + ? * INTERVAL '1 second'", [subtask.retry_delay_seconds])
        tables.jobQueue.currentSubtasks()
        .insert retrySubtask
  .then () ->
    tables.jobQueue.currentSubtasks()
    .where(id: subtask.id)
    .update
      status: status
      finished: knex.raw('NOW()')
  .then () ->
    tables.jobQueue.currentSubtasks()
    .where(id: subtask.id)
  .then (updatedSubtask) ->
    updatedSubtask[0].error = "#{error}"
    if error.stack
      updatedSubtask[0].stack = error.stack 
    tables.jobQueue.subtaskErrorHistory()
    .insert updatedSubtask[0]
  .then () ->
    if hard
      Promise.join cancelTask(subtask.task_name, 'hard fail'), sendNotification
        subject: 'subtask: hard fail'
        subtask: subtask
        error: "subtask: #{error}"

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
  tables.jobQueue.taskHistory()
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
  tables.jobQueue.taskHistory()
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
  tables.jobQueue.currentSubtasks()
  .whereNull('finished')
  .whereNotNull('started')
  .whereNotNull('kill_timeout_seconds')
  .whereRaw("started + #{SUBTASK_ZOMBIE_SLACK} + kill_timeout_seconds * INTERVAL '1 second' < NOW()")
  .then (subtasks=[]) ->
    Promise.map subtasks, (subtask) ->
      _handleSubtaskError(subtask, 'zombie', subtask.hard_fail_zombies, 'zombie')

_handleSuccessfulTasks = () ->
  # mark running tasks with no unfinished or error subtasks as successful
  tables.jobQueue.taskHistory()
  .where(status: 'running')
  .whereNotExists () ->
    tables.jobQueue.currentSubtasks(this)
    .whereRaw("task_name = #{tables.jobQueue.taskHistory.tableName}.name")
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
  tables.jobQueue.currentSubtasks()
  .select('task_name', knex.raw('MAX(finished) AS finished'))
  .groupBy('task_name')
  .then (tasks=[]) ->
    Promise.map tasks, (task) ->
      tables.jobQueue.taskHistory()
      .where
        current: true
        name: task.task_name
      .whereNotIn('status', ['preparing', 'running'])
      .update(finished: task.finished)

doMaintenance = () ->
  Promise.try () ->
    _handleSuccessfulTasks()
  .then () ->
    _setFinishedTimestamps()
  .then () ->
    _sendLongTaskWarnings()
  .then () ->
    _killLongTasks()
  .then () ->
    _handleZombies()
  .then () ->
    _setFinishedTimestamps()
    
updateTaskCounts = () ->
  knex.select(knex.raw('jq_update_task_counts()'))

getQueueNeeds = () ->
  queueNeeds = {}
  queueZombies = {}
  queueConfigPromise = tables.jobQueue.queueConfig()
  .select('*')
  .where(active: true)
  subtasksPromise = tables.jobQueue.currentSubtasks()
  .select('*')
  
  Promise.join queueConfigPromise , subtasksPromise, (queueConfigs, currentSubtasks) ->
    queueConfigs = _.indexBy(queueConfigs, 'name')
    for name of queueConfigs
      queueNeeds[name] = 0
      queueZombies[name] = 0
    currentSubtasks = _.groupBy(currentSubtasks, 'task_name')
    for taskName,taskList of currentSubtasks
      if !queueConfigs[taskList[0]?.queue_name]?.active
        # any task running on an inactive queue (or a queue without config) can be ignored without further processing
        continue
      taskSteps = _.groupBy(taskList, 'step_num')
      steps = _.keys(taskSteps).sort()
      # find and stop after the first step in each task that isn't "acceptably done", as we don't want to count
      # anything from steps past that (in this task)
      for step in steps
        # this step is "acceptably done" if it only consists of subtasks with soft fail, canceled, and/or success
        # statuses, and/or possibly timeout/zombie statuses if they isn't counted as a hard fail for the subtask
        acceptablyDone = true
        for subtask in taskSteps[step]
          if (subtask.status not in ['soft fail', 'canceled', 'success']) && (subtask.status != 'timeout' || subtask.hard_fail_timeouts) && (subtask.status != 'zombie' || subtask.hard_fail_zombies)
            acceptablyDone = false
          if subtask.status in ['queued', 'preparing', 'running'] && (!subtask.ignore_until? || subtask.ignore_until < Date.now())
            queueNeeds[subtask.queue_name]++
          if subtask.status == 'zombie'
            queueZombies[subtask.queue_name]++
        if !acceptablyDone
          continue
    result = []
    for name of queueConfigs
      # if the queue has nothing that's not a zombie, let it scale down to 0; otherwise we need to leave something
      # running for the zombies too, or else we could get ourselves stuck in deadlock where zombies have eaten all the
      # resources (like they do)
      needs = 0
      if queueNeeds[name] > 0
        needs = queueNeeds[name] * queueConfigs[name].priority_factor + queueZombies[name]
        needs /= queueConfigs[name].subtasks_per_process * queueConfigs[name].processes_per_dyno
        needs = Math.ceil(needs)
      result.push(name: name, quantity: needs)
    return result

# convenience function to get another subtask config and then enqueue it (paginated) based on the current subtask 
queueSubsequentPaginatedSubtask = (transaction, currentSubtask, total, maxPage, laterSubtaskName) ->
  getSubtaskConfig(transaction, laterSubtaskName, currentSubtask.task_name)
  .then (laterSubtask) ->
    queuePaginatedSubtask(transaction, currentSubtask.batch_id, currentSubtask.task_data, total, maxPage, laterSubtask)
    
queuePaginatedSubtask = (transaction, batchId, taskData, total, maxPage, subtask) -> Promise.try () ->
  if total == 0
    return
  subtasks = Math.ceil(total/maxPage)
  subtasksQueued = 0
  countHandled = 0
  data = []
  for i in [1..subtasks]
    datum =
      offset: subtasksQueued
      count: Math.ceil((total-countHandled)/(subtasks-subtasksQueued))
    data.push datum
    subtasksQueued++
    countHandled += datum.count
  queueSubtask(transaction, batchId, taskData, subtask, data)
  
getSubtaskConfig = (transaction, subtaskName, taskName) ->
  tables.jobQueue.subtaskConfig(transaction)
  .where
    name: subtaskName
    task_name: taskName
  .then (subtasks) ->
    if !subtasks?.length
      throw new Error("specified subtask not found: #{taskName}/#{subtaskName}")
    return subtasks[0]

runWorker = (queueConfig, id) ->
  if cluster.worker?
    prefix = "<#{queueConfig.name}-#{cluster.worker.id}-#{id}>"
  else
    prefix = "<#{queueConfig.name}-#{id}>"
  getQueuedSubtask(queueConfig.name)
  .then (subtask) ->
    if subtask?
      logger.info "#{prefix} Executing subtask: #{subtask.task_name}/#{subtask.name}<#{JSON.stringify(subtask.data)}>"
      executeSubtask(subtask)
    else
      logger.debug "#{prefix} No subtask ready for execution, waiting..."
      Promise.delay(30000) # poll again in 30 seconds
  .then runWorker.bind(null, queueConfig, id)
        


module.exports =
  withSchedulingLock: withSchedulingLock
  queueReadyTasks: queueReadyTasks
  queueTask: queueTask
  queueSubtasks: queueSubtasks
  queueSubtask: queueSubtask
  queueSubsequentSubtask: queueSubsequentSubtask
  cancelTask: cancelTask
  executeSubtask: executeSubtask
  getQueuedSubtask: getQueuedSubtask
  doMaintenance: doMaintenance
  sendNotification: sendNotification
  updateTaskCounts: updateTaskCounts
  getQueueNeeds: getQueueNeeds
  queuePaginatedSubtask: queuePaginatedSubtask
  queueSubsequentPaginatedSubtask: queueSubsequentPaginatedSubtask
  getSubtaskConfig: getSubtaskConfig
  runWorker: runWorker
  SoftFail: SoftFail
  HardFail: HardFail
  knex: knex
