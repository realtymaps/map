require '../config/promisify'
path = require 'path'
loaders = require './util.loaders'
Promise = require 'bluebird'
sqlHelpers = require './util.sql.helpers'
logger = require('../config/logger').spawn('jobQueue')
analyzeValue = require '../../common/utils/util.analyzeValue'
_ = require 'lodash'
{notification} = require './util.notifications.coffee'
tables = require '../config/tables'
cluster = require 'cluster'
memoize = require 'memoizee'
config = require '../config/config'
keystore = require '../services/service.keystore'
{PartiallyHandledError, isUnhandled} = require './errors/util.error.partiallyHandledError'
TaskImplementation = require '../tasks/util.taskImplementation'
dbs = require '../config/dbs'
{HardFail, SoftFail, TaskNotImplemented} = require './errors/util.error.jobQueue'


# to understand at a high level most of what is going on in this code and how to write a task to be utilized by this
# module, go to https://realtymaps.atlassian.net/wiki/display/DN/Job+queue%3A+the+developer+guide

MAINTENANCE_TIMESTAMP = 'job queue maintenance timestamp'
sendNotification = notification('jobQueue')


_summary = (subtask) ->
  JSON.stringify(_.omit(subtask.data,['values', 'ids']))

_withDbLock = (lockId, handler) ->
  id = cluster.worker?.id ? 'X'
  dbs.get('main').transaction (transaction) ->
    logger.spawn('dbLock').debug () -> "@@@@@@@@@@@@@@@@@@<#{id}>   Getting lock: #{lockId}"
    transaction
    .select(dbs.get('main').raw("pg_advisory_xact_lock(#{config.JOB_QUEUE.LOCK_KEY}, #{lockId})"))
    .then () ->
      logger.spawn('dbLock').debug () -> "==================<#{id}>  Acquired lock: #{lockId}"
      handler(transaction)
    .finally () ->
      logger.spawn('dbLock').debug () -> "------------------<#{id}> Releasing lock: #{lockId}"

queueReadyTasks = (opts={}) -> Promise.try () ->
  batchId = (Date.now()).toString(36)
  overrideRunNames = []
  overrideSkipNames = []
  readyPromises = []
  # load all task definitions to check for overridden "ready" method
  taskImpls = loaders.loadSubmodules(path.join(__dirname, '../tasks'), /^task\.(\w+)\.coffee$/)
  Promise.map Object.keys(taskImpls), (taskName) ->
    taskImpl = taskImpls[taskName]
    # task might define its own logic for determining if it should run
    taskImpl.ready?()
    .then (override) ->
      # if the result is true, run this task (as long as it is active and is past any ignore_until)
      if override == true
        overrideRunNames.push(taskName)
      # if the result is false, /don't/ run this task (no matter what)
      else if override == false
        overrideSkipNames.push(taskName)
      # otherwise, rely on default ready-checking logic
  .then () ->
    _withDbLock config.JOB_QUEUE.SCHEDULING_LOCK_ID, (transaction) ->
      tables.jobQueue.taskConfig(transaction: transaction)
      .select()
      .where(active: true)                  # only consider active tasks
      .whereRaw("COALESCE(ignore_until, '1970-01-01'::TIMESTAMP) <= NOW()") # only consider tasks whose time has come
      .where () ->
        sqlHelpers.whereIn(this, 'name', overrideRunNames)        # run if in the override run list ...
        sqlHelpers.orWhereNotIn(this, 'name', overrideSkipNames)  # ... or it's not in the override skip list ...
        .whereNotExists () ->                                     # ... and we can't find a history entry such that ...
          tables.jobQueue.taskHistory(transaction: this)
          .select(1)
          .where(current: true)
          .whereRaw("#{tables.jobQueue.taskConfig.tableName}.name = #{tables.jobQueue.taskHistory.tableName}.name")
          .where () ->
            this
            .whereIn('status', ['running', 'preparing'])             # ... it's currently running or preparing to run ...
            .orWhere () ->
              this
              .where(status: 'success')                 # ... or it was successful
              .where () ->
                this
                .whereNull("#{tables.jobQueue.taskConfig.tableName}.repeat_period_minutes")   # ... and it isn't set to repeat ...
                .orWhereRaw("started + #{tables.jobQueue.taskConfig.tableName}.repeat_period_minutes * INTERVAL '1 minute' > NOW()") # or hasn't passed its success repeat delay
            .orWhere () ->   # ... or it failed and hasn't passed its fail retry delay
              this
              .whereIn('status', ['hard fail','canceled','timeout'])           # ... or it failed
              .where () ->
                this
                .whereNull("#{tables.jobQueue.taskConfig.tableName}.fail_retry_minutes")   # ... and it isn't set to retry ...
                .orWhereRaw("finished + #{tables.jobQueue.taskConfig.tableName}.fail_retry_minutes * INTERVAL '1 minute' > NOW()") # or hasn't passed its fail retry delay
      .then (readyTasks=[]) ->
        Promise.map readyTasks, (task) ->
          queueTask(transaction, batchId, task, '<scheduler>')
          .catch TaskNotImplemented, (err) ->
            logger.error "#{err}"
            if opts.dieOnMissingTask
              throw err

queueManualTask = (taskName, initiator) ->
  if !taskName
    throw new Error('Task name required!')
  dbs.get('main').transaction (transaction) ->
    # need to be sure it's not already running
    tables.jobQueue.taskHistory(transaction: transaction)
    .select()
    .where
      current: true
      name: taskName
    .then (task) ->
      if task?.length && !task[0].finished
        Promise.reject(new Error("Refusing to queue task #{taskName}; another instance is currently #{task[0].status}, started #{task[0].started} by #{task[0].initiator}"))
    .then () ->
      tables.jobQueue.taskConfig(transaction: transaction)
      .select()
      .where(name: taskName)
      .then (result) ->
        if result.length == 0
          throw new Error("Task not found: #{taskName}")
        else if result.length == 1
          batchId = (Date.now()).toString(36)
          logger.info "Queueing #{taskName} for #{initiator} using batchId #{batchId}"
          queueTask(transaction, batchId, result[0], initiator)

queueTask = (transaction, batchId, task, initiator) -> Promise.try () ->
  logger.spawn("task:#{task.name}").debug () -> "Queueing task for batchId #{batchId}: #{task.name}"
  tables.jobQueue.taskHistory(transaction: transaction)
  .where(name: task.name)
  .update(current: false)  # only the most recent entry in the history should be marked current
  .then () ->
    tables.jobQueue.taskHistory(transaction: transaction)
    .insert
      name: task.name
      data: task.data
      batch_id: batchId
      initiator: initiator
      warn_timeout_minutes: task.warn_timeout_minutes
      kill_timeout_minutes: task.kill_timeout_minutes
  .then () -> # clear out any subtasks for prior runs of this task
    tables.jobQueue.currentSubtasks(transaction: transaction)
    .where(task_name: task.name)
    .whereNot(batch_id: batchId)
    .delete()
  .then () ->  # now to enqueue (initial) subtasks
    # see if the task wants to specify the subtasks to run (vs using static config)
    TaskImplementation.getTaskCode(task.name)
  .then (taskImpl) ->
    taskImpl.initialize(transaction, batchId, task)
  .then (count) ->
    tables.jobQueue.taskHistory(transaction: transaction)
    .where
      name: task.name
      current: true
    .update
      subtasks_created: count
      status: 'running'
      status_changed: dbs.get('main').raw('NOW()')

_checkTask = (transaction, batchId, taskName) ->
  # need to get taskData such that we fail if the task is not still preparing or running i.e. has errored in some way
  tables.jobQueue.taskHistory(transaction: transaction)
  .where
    current: true
    name: taskName
    batch_id: batchId
  .whereIn('status', ['preparing', 'running'])
  .then (task) ->
    if !task?.length
      # use undefined since the task_data could legitimately be null
      return undefined
    task?[0]?.data

queueSubtasks = ({transaction, batchId, subtasks, concurrency}) -> Promise.try () ->
  if !subtasks?.length
    return 0
  _checkTask(transaction, batchId, subtasks[0].task_name)
  .then (taskData) ->
    # need to make sure we don't continue to queue subtasks if the task has errorred in some way
    if taskData == undefined
      # return an array indicating we queued 0 subtasks
      logger.spawn("task:#{subtasks[0].task_name}").debug () -> "Refusing to queue subtasks (parent task might have terminated): #{_.pluck(subtasks, 'name').join(', ')}"
      return [0]
    Promise.all _.map subtasks, (subtask) -> # can't use bind here because it passes in unwanted params
      queueSubtask({transaction, batchId, taskData, subtask, concurrency})
  .then (counts) ->
    return _.reduce counts, (sum, count) -> sum+count

# convenience function to get another subtask config and then enqueue it based on the current subtask
queueSubsequentSubtask = ({transaction, subtask, laterSubtaskName, manualData, replace, concurrency}) ->
  subtaskName = "#{subtask.task_name}_#{laterSubtaskName}"
  getSubtaskConfig(transaction, subtaskName, subtask.task_name)
  .then (laterSubtask) ->
    queueSubtask({transaction, batchId: subtask.batch_id, subtask: laterSubtask, manualData, replace, concurrency})

queueSubtask = ({transaction, batchId, taskData, subtask, manualData, replace, concurrency}) -> Promise.try () ->
  if !subtask.active
    logger.spawn("task:#{subtask.task_name}").debug () -> "Refusing to queue inactive subtask for batchId #{batchId}: #{subtask.name}"
    return 0
  if manualData?
    if replace
      subtaskData = manualData
    else
      if _.isArray manualData && _.isArray subtask.data
        throw new Error("array passed as non-replace manualData for subtask with array data: #{subtask.name}")
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
  # maybe we've already gotten the data and checked to be sure the task is still running
  if taskData != undefined
    taskDataPromise = Promise.resolve(taskData)
  else
    taskDataPromise = _checkTask(transaction, batchId, subtask.task_name)
  taskDataPromise
  .then (freshTaskData) ->
    # need to make sure we don't queue the subtask if the task has errored in some way
    if freshTaskData == undefined
      # return 0 to indicate we queued 0 subtasks
      logger.spawn("task:#{subtask.task_name}").debug () -> "Refusing to queue subtask for batchId #{batchId} (parent task might have terminated): #{subtask.name}"
      return 0
    suffix = if subtaskData?.length? then "[#{subtaskData.length}]" else "<#{_summary(subtask)}>"
    logger.spawn("task:#{subtask.task_name}").debug () -> "Queueing subtask for batchId #{batchId}: #{subtask.name}#{suffix}"
    if _.isArray subtaskData    # an array for data means to create multiple subtasks, one for each element of data
      Promise.map subtaskData, (data, index) ->
        singleSubtask = _.clone(subtask)
        delete singleSubtask.active
        if concurrency
          singleSubtask.step_num += Math.floor(index/concurrency)
        singleSubtask.data = data
        if mergeData?
          _.extend(singleSubtask.data, mergeData)
        singleSubtask.task_data = freshTaskData
        singleSubtask.task_step = "#{singleSubtask.task_name}_#{('00000'+(singleSubtask.step_num||'FINAL')).slice(-5)}"  # this is needed by a stored proc, 0-padding
        singleSubtask.batch_id = batchId
        tables.jobQueue.currentSubtasks(transaction: transaction)
        .insert singleSubtask
      .then () ->
        return subtaskData.length
    else
      singleSubtask = _.clone(subtask)
      delete singleSubtask.active
      singleSubtask.data = subtaskData
      singleSubtask.task_data = freshTaskData
      singleSubtask.task_step = "#{subtask.task_name}_#{('00000'+(subtask.step_num||'FINAL')).slice(-5)}"  # this is needed by a stored proc, 0-padding
      singleSubtask.batch_id = batchId
      tables.jobQueue.currentSubtasks(transaction: transaction)
      .insert singleSubtask
      .then () ->
        return 1

cancelAllRunningTasks = (forget, status='canceled', withPrejudice=false) ->
  logger.spawn("manual").debug("Canceling all tasks -- forget:#{forget}, status:#{status}, withPrejudice:#{withPrejudice}")
  tables.jobQueue.taskHistory()
  .where
    current: true
  .whereNull('finished')
  .map (task) ->
    cancelTask(task.name, status, withPrejudice)
    .then () ->
      if forget
        tables.jobQueue.taskHistory()
        .where
          name: task.name
          current: true
        .whereNotNull('finished')
        .delete()

cancelTask = (taskName, status='canceled', withPrejudice=false) ->
  # note that this doesn't cancel subtasks that are already running; there's no easy way to do that except within the
  # worker that's executing that subtask, and we're not going to make that worker poll to watch for a cancel message
  logger.spawn("cancels").debug("Cancelling task: #{taskName}, status:#{status}, withPrejudice:#{withPrejudice}")
  dbs.get('main').transaction (transaction) ->
    tables.jobQueue.taskHistory(transaction: transaction)
    .where
      name: taskName
      current: true
    .whereNull('finished')
    .update
      status: status
      status_changed: dbs.get('main').raw('NOW()')
      finished: dbs.get('main').raw('NOW()')
    .then () ->
      subtaskCancelQuery = tables.jobQueue.currentSubtasks(transaction: transaction)
      .where(task_name: taskName)
      if withPrejudice
        subtaskCancelQuery = subtaskCancelQuery
        .whereNull('finished')
      else
        subtaskCancelQuery = subtaskCancelQuery
        .where(status: 'queued')
      subtaskCancelQuery
      .update
        status: 'canceled'
        finished: dbs.get('main').raw('NOW()')
      .then (count) ->
        logger.spawn("task:#{taskName}").debug () -> "Canceled #{count} subtasks of #{taskName}."

# convenience helper for dev/troubleshooting
requeueManualTask = (taskName, initiator, withPrejudice=false) ->
  logger.spawn("manual").debug("Requeuing manual task: #{taskName}, for initiator: #{initiator}")
  cancelTask(taskName, 'canceled', withPrejudice)
  .then () ->
    queueManualTask(taskName, initiator)

executeSubtask = (subtask, prefix) ->
  tables.jobQueue.currentSubtasks()
  .where(id: subtask.id)
  .update
    status: 'running'
    started: dbs.get('main').raw('NOW()')
  .then () ->
    TaskImplementation.getTaskCode(subtask.task_name)
  .then (taskImpl) ->
    subtaskPromise = taskImpl.executeSubtask(subtask)
    .cancellable()
    .then () ->
      logger.spawn("task:#{subtask.task_name}").debug () -> "#{prefix} finished subtask #{subtask.name}"
      tables.jobQueue.currentSubtasks()
      .where(id: subtask.id)
      .update
        status: 'success'
        finished: dbs.get('main').raw('NOW()')
    if subtask.kill_timeout_seconds
      subtaskPromise = subtaskPromise
      .timeout(subtask.kill_timeout_seconds*1000)
      .catch Promise.TimeoutError, (err) ->
        _handleSubtaskError({prefix, subtask, status: 'timeout', hard: subtask.hard_fail_timeouts, error: 'timeout'})
    if subtask.warn_timeout_seconds
      doNotification = () ->
        sendNotification
          subject: 'subtask: long run warning'
          subtask: subtask
          error: "subtask has been running for longer than #{subtask.warn_timeout_seconds} seconds"
      warnTimeout = setTimeout(doNotification, subtask.warn_timeout_seconds)
      subtaskPromise = subtaskPromise
      .finally () ->
        clearTimeout(warnTimeout)
    return subtaskPromise
  .then () ->
    logger.spawn("task:#{subtask.task_name}").debug () -> "#{prefix} subtask #{subtask.name} updated with success status"
  .catch SoftFail, (err) ->
    _handleSubtaskError({prefix, subtask, status: 'soft fail', hard: false, error: err})
  .catch HardFail, (err) ->
    _handleSubtaskError({prefix, subtask, status: 'hard fail', hard: true, error: err})
  .catch PartiallyHandledError, (err) ->
    _handleSubtaskError({prefix, subtask, status: 'infrastructure fail', hard: true, error: err})
  .catch isUnhandled, (err) ->
    logger.error("Unexpected error caught during job execution: #{analyzeValue.getSimpleDetails(err)}")
    _handleSubtaskError({prefix, subtask, status: 'infrastructure fail', hard: true, error: err})
  .catch (err) -> # if we make it here, then we probably can't rely on the db for error reporting
    logger.error("#{prefix} Error caught while handling errors; major db problem likely!  subtask: #{subtask.name}")
    sendNotification
      subject: 'major db interaction problem'
      subtask: subtask
      error: err
    throw err

_handleSubtaskError = ({prefix, subtask, status, hard, error}) ->
  logger.spawn("task:#{subtask.task_name}").debug () -> "#{prefix} error caught for subtask #{subtask.name}: #{JSON.stringify({errorType: status, hard, error: error.toString()})}"
  Promise.try () ->
    if hard
      logger.error("#{prefix} Hard error executing subtask for batchId #{subtask.batch_id}, #{subtask.name}<#{_summary(subtask)}>: #{error}")
    else
      if subtask.retry_max_count? && subtask.retry_num >= subtask.retry_max_count
        if subtask.hard_fail_after_retries
          hard = true
          status = 'hard fail'
          error = "max retries exceeded due to: #{error}"
          logger.error("#{prefix} Hard error executing subtask for batchId #{subtask.batch_id}, #{subtask.name}<#{_summary(subtask)}>: #{error}")
        else
          logger.warn("#{prefix} Soft error executing subtask for batchId #{subtask.batch_id}, #{subtask.name}<#{_summary(subtask)}>: #{error}")
      else
        retrySubtask = _.omit(subtask, 'id', 'enqueued', 'started', 'status')
        retrySubtask.retry_num += 1
        retrySubtask.ignore_until = dbs.get('main').raw("NOW() + ? * INTERVAL '1 second'", [subtask.retry_delay_seconds])
        _checkTask(null, subtask.batch_id, subtask.task_name)
        .then (taskData) ->
          # need to make sure we don't continue to retry subtasks if the task has errored in some way
          if taskData == undefined
            logger.info("#{prefix} Can't retry subtask (task is no longer running) for batchId #{subtask.batch_id}, #{subtask.name}<#{_summary(retrySubtask)}>: #{error}")
            return
          logger.info("#{prefix} Queuing retry subtask for batchId #{subtask.batch_id}, #{subtask.name}<#{_summary(retrySubtask)}>: #{error}")
          tables.jobQueue.currentSubtasks()
          .insert retrySubtask
  .then () ->
    tables.jobQueue.currentSubtasks()
    .where(id: subtask.id)
    .update
      status: status
      finished: dbs.get('main').raw('NOW()')
    .returning('*')
  .then (updatedSubtask) ->
    # handle condition where currentSubtasks table gets cleared before the update -- it shouldn't happen under normal
    # conditions, but then again we're in an error handler so who knows what could be going on by the time we get here.
    # ideally we want to get a fresh copy of the data, but if it's gone, just use what we already had
    if !updatedSubtask?[0]?
      errorSubtask = _.clone(subtask)
      errorSubtask.status = status
      errorSubtask.finished = dbs.get('main').raw('NOW()')
    else
      errorSubtask = updatedSubtask[0]
    errorSubtask.error = "#{error}"
    details = analyzeValue.getSimpleDetails(error)
    if details != errorSubtask.error
      errorSubtask.stack = details
    tables.jobQueue.subtaskErrorHistory()
    .insert errorSubtask
  .then () ->
    if hard
      Promise.join cancelTask(subtask.task_name, 'hard fail'), sendNotification
        subject: 'subtask: hard fail'
        subtask: subtask
        error: "subtask: #{error}"

_getQueueLockId = (queueName) ->
  tables.jobQueue.queueConfig()
  .select('lock_id')
  .where(name: queueName)
  .then (queueLockId) ->
    queueLockId[0].lock_id
_getQueueLockId = memoize.promise(_getQueueLockId, primitive: true)

# TODO: should this be rewritten to use a query built by knex instead of a stored proc?
getQueuedSubtask = (queueName) ->
  _getQueueLockId(queueName)
  .then (queueLockId) ->
    _withDbLock queueLockId, (transaction) ->
      transaction
      .select('*')
      .from(transaction.raw('jq_get_next_subtask(?)', [queueName]))
      .then (results) ->
        if !results?[0]?.id?
          return null
        else
          return results[0]

_sendLongTaskWarnings = (transaction=null) ->
  # warn about long-running tasks
  tables.jobQueue.taskHistory(transaction: transaction)
  .whereNull('finished')
  .whereNotNull('warn_timeout_minutes')
  .where(current: true)
  .whereRaw("started + warn_timeout_minutes * INTERVAL '1 minute' < NOW()")
  .then (tasks=[]) ->
    sendNotification
      subject: 'task: long run warning'
      tasks: tasks
      error: 'tasks have been running for longer than expected'

_killLongTasks = (transaction=null) ->
  # kill long-running tasks
  tables.jobQueue.taskHistory(transaction: transaction)
  .whereNull('finished')
  .whereNotNull('kill_timeout_minutes')
  .where(current: true)
  .whereRaw("started + kill_timeout_minutes * INTERVAL '1 minute' < NOW()")
  .then (tasks=[]) ->
    cancelPromise = Promise.map tasks, (task) ->
      logger.warn("Task for batchId #{task.batch_id} has timed out: #{task.name}")
      cancelTask(task.name, 'timeout')
    notificationPromise = sendNotification
      subject: 'task: long run killed'
      tasks: tasks
      error: 'tasks have been running for longer than expected'
    Promise.join cancelPromise, notificationPromise

_handleZombies = (transaction=null) ->
  # mark subtasks that should have been suicidal (but maybe disappeared instead) as zombies, and possibly cancel their tasks
  tables.jobQueue.currentSubtasks(transaction: transaction)
  .whereNull('finished')
  .whereNotNull('started')
  .whereNotNull('kill_timeout_seconds')
  .whereRaw("started + #{config.JOB_QUEUE.SUBTASK_ZOMBIE_SLACK} + kill_timeout_seconds * INTERVAL '1 second' < NOW()")
  .then (subtasks=[]) ->
    Promise.map subtasks, (subtask) ->
      _handleSubtaskError({prefix: "<#{subtask.queue_name}-unknown>", subtask, status: 'zombie', hard: subtask.hard_fail_zombies, error: 'zombie'})

_handleSuccessfulTasks = (transaction=null) ->
  # mark running tasks with no unfinished or error subtasks as successful
  tables.jobQueue.taskHistory(transaction: transaction)
  .where(status: 'running')
  .whereNotExists () ->
    tables.jobQueue.currentSubtasks(transaction: this)
    .select(1)
    .whereRaw("#{tables.jobQueue.currentSubtasks.tableName}.task_name = #{tables.jobQueue.taskHistory.tableName}.name")
    .where () ->
      this
      .whereNull("#{tables.jobQueue.currentSubtasks.tableName}.finished")
      .orWhereIn("#{tables.jobQueue.currentSubtasks.tableName}.status", ['hard fail', 'infrastructure fail', 'canceled'])
      .orWhere () ->
        this.where("#{tables.jobQueue.currentSubtasks.tableName}.status", 'timeout')
        .where("#{tables.jobQueue.currentSubtasks.tableName}.hard_fail_timeouts", true)
      .orWhere () ->
        this.where("#{tables.jobQueue.currentSubtasks.tableName}.status", 'zombie')
        .where("#{tables.jobQueue.currentSubtasks.tableName}.hard_fail_zombies", true)
  .update
    status: 'success'
    status_changed: dbs.get('main').raw('NOW()')

_setFinishedTimestamps = (transaction=null) ->
  # set the correct 'finished' value for tasks based on finished timestamps for their subtasks
  tables.jobQueue.currentSubtasks(transaction: transaction)
  .select('task_name', dbs.get('main').raw('MAX(finished) AS finished'))
  .groupBy('task_name')
  .then (tasks=[]) ->
    Promise.map tasks, (task) ->
      tables.jobQueue.taskHistory(transaction: transaction)
      .where
        current: true
        name: task.task_name
      .whereNotIn('status', ['preparing', 'running'])
      .update(finished: task.finished)

_updateTaskCounts = (transaction) ->
  transaction.select(dbs.get('main').raw('jq_update_task_counts()'))

doMaintenance = () ->
  maintenanceLogger = logger.spawn("maintenance")
  maintenanceLogger.debug('Doing maintenance...')
  _withDbLock config.JOB_QUEUE.MAINTENANCE_LOCK_ID, (transaction) ->
    maintenanceLogger.debug('Getting last maintenance timestamp...')
    keystore.getValue(MAINTENANCE_TIMESTAMP, defaultValue: 0)
    .then (timestamp) ->
      if Date.now() - timestamp < config.JOB_QUEUE.MAINTENANCE_WINDOW
        maintenanceLogger.debug('Skipping maintenance.')
        return
      Promise.try () ->
        maintenanceLogger.debug('_handleSuccessfulTasks...')
        _handleSuccessfulTasks(transaction)
      .then () ->
        maintenanceLogger.debug('_setFinishedTimestamps...')
        _setFinishedTimestamps(transaction)
      .then () ->
        maintenanceLogger.debug('_sendLongTaskWarnings...')
        _sendLongTaskWarnings(transaction)
      .then () ->
        maintenanceLogger.debug('_killLongTasks...')
        _killLongTasks(transaction)
      .then () ->
        maintenanceLogger.debug('_handleZombies...')
        _handleZombies(transaction)
      .then () ->
        maintenanceLogger.debug('_setFinishedTimestamps...')
        _setFinishedTimestamps(transaction)
      .then () ->
        maintenanceLogger.debug('_updateTaskCounts...')
        _updateTaskCounts(transaction)
      .then () ->
        maintenanceLogger.debug('Setting last maintenance timestamp...')
        keystore.setValue(MAINTENANCE_TIMESTAMP, Date.now())

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
    for taskName,subtaskList of currentSubtasks
      if !queueConfigs[subtaskList[0]?.queue_name]?.active
        # any task running on an inactive queue (or a queue without config) can be ignored without further processing
        continue
      taskSteps = _.groupBy(subtaskList, 'task_step')
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
            queueNeeds[subtask.queue_name] += 1
          if subtask.status == 'zombie'
            queueZombies[subtask.queue_name] += 1
        if !acceptablyDone
          break
    result = []
    for name of queueConfigs
      # if the queue has nothing that's not a zombie, let it scale down to 0; otherwise we need to leave something
      # running for the zombies too, or else we could get ourselves stuck in deadlock where zombies have eaten all the
      # resources (like they do)
      needs = 0
      if queueNeeds[name] > 0
        needs = queueNeeds[name] * queueConfigs[name].priority_factor + queueZombies[name]
        needs /= (queueConfigs[name].subtasks_per_process * queueConfigs[name].processes_per_dyno)
        needs = Math.ceil(needs)
      result.push(name: name, quantity: needs)
    return result

# convenience function to get another subtask config and then enqueue it (paginated) based on the current subtask
queueSubsequentPaginatedSubtask = ({transaction, subtask, totalOrList, maxPage, laterSubtaskName, mergeData, concurrency}) ->
  getSubtaskConfig(transaction, "#{subtask.task_name}_#{laterSubtaskName}", subtask.task_name)
  .then (laterSubtask) ->
    queuePaginatedSubtask({transaction, batchId: subtask.batch_id, totalOrList, maxPage, subtask: laterSubtask, mergeData, concurrency})

queuePaginatedSubtask = ({transaction, batchId, taskData, totalOrList, maxPage, subtask, mergeData, concurrency}) -> Promise.try () ->
  if _.isArray(totalOrList)
    list = totalOrList
    total = totalOrList.length
  else
    list = null
    total = totalOrList
  total = Number(total)
  if !total
    return
  subtasks = Math.ceil(total/maxPage)
  subtasksQueued = 0
  countHandled = 0
  data = []
  for i in [1..subtasks]
    datum =
      offset: countHandled
      count: Math.ceil((total-countHandled)/(subtasks-subtasksQueued))
      i: i
      of: subtasks
    if list
      datum.values = list.slice(datum.offset, datum.offset+datum.count)
    if mergeData
      _.extend(datum, mergeData)
    data.push datum
    subtasksQueued += 1
    countHandled += datum.count
  queueSubtask({transaction, batchId, taskData, subtask, manualData: data, concurrency})

getSubtaskConfig = (transaction, subtaskName, taskName) ->
  tables.jobQueue.subtaskConfig(transaction: transaction)
  .where
    name: subtaskName
    task_name: taskName
  .then (subtasks) ->
    if !subtasks?.length
      throw new Error("specified subtask not found: #{taskName}/#{subtaskName}")
    return subtasks[0]

runWorker = (queueName, id, quit=false) ->
  if cluster.worker?
    prefix = "<#{queueName}-#{cluster.worker.id}-#{id}>"
  else
    prefix = "<#{queueName}-#{id}>"
  logger.spawn("queue:#{queueName}").debug () -> "#{prefix} worker starting..."
  _runWorkerImpl(queueName, prefix, quit)

_runWorkerImpl = (queueName, prefix, quit) ->
  logger.spawn("queue:#{queueName}").debug () -> "#{prefix} Getting next subtask..."
  getQueuedSubtask(queueName)
  .then (subtask) ->
    nextIteration = _runWorkerImpl.bind(null, queueName, prefix, quit)
    if subtask?
      logger.info "#{prefix} Executing subtask for batchId #{subtask.batch_id}: #{subtask.name}<#{_summary(subtask)}>(retry: #{subtask.retry_num})"
      return executeSubtask(subtask, prefix)
      .then nextIteration

    if !quit && !logger.isEnabled("queue:#{queueName}")
      return Promise.delay(30000) # poll again in 30 seconds
      .then nextIteration

    tables.jobQueue.currentSubtasks()
    .count('* as count')
    .where(queue_name: queueName)
    .whereNull('finished')
    .then (moreSubtasks) ->
      if quit && !parseInt(moreSubtasks?[0]?.count)
        logger.spawn("queue:#{queueName}").debug () -> "#{prefix} Queue is empty; quitting worker."
        Promise.resolve()
      else
        logger.spawn("queue:#{queueName}").debug () -> "#{prefix} No subtask ready for execution; waiting... (#{moreSubtasks[0].count} unfinished subtasks)"
        Promise.delay(30000) # poll again in 30 seconds
        .then nextIteration

# determines the start of the last time a task ran, or defaults to the Epoch (Jan 1, 1970) if
# there are no runs found.  By default only considers successful runs.
getLastTaskStartTime = (taskName, successOnly = true) ->
  criteria =
    name: taskName
    current: false
  if successOnly
    criteria.status = 'success'
  tables.jobQueue.taskHistory()
  .max('started AS last_start_time')
  .where(criteria)
  .then (result) ->
    result?[0]?.last_start_time || new Date(0)

module.exports = {
  queueReadyTasks
  queueTask
  queueManualTask
  requeueManualTask
  queueSubtasks
  queueSubtask
  queueSubsequentSubtask
  cancelTask
  executeSubtask
  getQueuedSubtask
  doMaintenance
  sendNotification
  getQueueNeeds
  queuePaginatedSubtask
  queueSubsequentPaginatedSubtask
  getSubtaskConfig
  runWorker
  getLastTaskStartTime
  cancelAllRunningTasks
}
