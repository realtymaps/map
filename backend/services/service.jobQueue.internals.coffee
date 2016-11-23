require '../config/promisify'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('jobQueue')
analyzeValue = require '../../common/utils/util.analyzeValue'
_ = require 'lodash'
notifications = require './service.notifications'
tables = require '../config/tables'
cluster = require 'cluster'
memoize = require 'memoizee'
config = require '../config/config'
dbs = require '../config/dbs'
jobQueueErrors = require '../utils/errors/util.error.jobQueue'
TaskImplementation = require '../tasks/util.taskImplementation'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
# to understand at a high level most of what is going on in this code and how to write a task to be utilized by this
# module, go to https://realtymaps.atlassian.net/wiki/display/DN/Job+queue%3A+the+developer+guide

enqueueNotification = notifications.notifyFlat {
  type: 'jobQueue'
  method: 'email'
}


TH = tables.jobQueue.taskHistory.tableName
TC = tables.jobQueue.taskConfig.tableName


getPossiblyReadyTasks = (transaction) ->
  tables.jobQueue.taskConfig(transaction: transaction)                                  # get task config...
  .leftJoin TH,                                                                         # (left outer) joined with task history, when:
    "#{TH}.current": tables.jobQueue.taskHistory.raw('true')                                # it is the most recent run for that task...
    "#{TC}.name": "#{TH}.name"                                                              # and task names match
  .select("#{TC}.*")                                                                    # only consider:
  .where("#{TC}.active": true)                                                              # active tasks...
  .whereRaw("COALESCE(#{TC}.ignore_until, '1970-01-01'::TIMESTAMP) <= NOW()")               # whose time has come...
  .where () ->                                                                              # that...
    @whereNull("#{TH}.name")                                                                    # never ran...
    .orWhereNotNull("#{TH}.finished")                                                           # or are done running...
    .whereNot () ->                                                                                 # but not:
      @where("#{TH}.status": 'success')                                                                 # tasks that succeeded...
      .whereRaw("#{TH}.started+COALESCE(#{TC}.repeat_period_minutes,'0')*'1 minute'::INTERVAL>NOW()")   # if they haven't passed any success repeat delay
    .whereNot () ->                                                                                 # and not:
      @whereIn("#{TH}.status", ['hard fail','canceled','timeout'])                                      # tasks that failed...
      .whereRaw("#{TH}.finished+COALESCE(#{TC}.fail_retry_minutes,'0')*'1 minute'::INTERVAL>NOW()")     # if they haven't passed any fail retry delay
  .whereNotExists () ->
    tables.jobQueue.taskHistory(transaction: @)                                             # and with no tasks...
    .select(1)
    .where(current: true)                                                                       # that are the most recent run for the task...
    .whereNull('finished')                                                                      # and are still running...
    .whereRaw("#{TC}.blocked_by_tasks \\? name")                                                # and block this task from running
  .whereNotExists () ->
    tables.config.keystore(transaction: @)                                                  # and with no keystore rows...
    .select(1)
    .where(namespace: 'locks')                                                                  # that are locks...
    .whereRaw("#{TC}.blocked_by_locks \\? key")                                                 # which block this task...
    .whereRaw("value::TEXT = 'true'")                                                           # and are currently set
  .orderByRaw("#{TH}.started ASC NULLS FIRST")

summary = (subtask) ->
  JSON.stringify(_.omit(subtask.data,['values', 'ids']))


withDbLock = ({lockId, maxWaitSeconds, retryIntervalSeconds=2}, handler) -> new Promise (resolve, reject) ->
  start = Date.now()
  id = cluster.worker?.id ? 'X'
  dbLockLogger = logger.spawn('dbLock')
  attempt = (attemptNum) ->
    retry = false
    dbs.transaction 'main', (transaction) ->
      dbLockLogger.debug () -> "---- <#{id}>   Attempting to get lock (attempt ##{attemptNum}): #{lockId}"
      transaction
      .select(dbs.get('main').raw("pg_try_advisory_xact_lock(#{config.JOB_QUEUE.LOCK_KEY}, #{lockId}) AS got_lock"))
      .then ([result]) ->
        if result.got_lock
          dbLockLogger.debug () -> "---- <#{id}>  Acquired lock: #{lockId}"
          handler(transaction)
          .finally () ->
            dbLockLogger.debug () -> "---- <#{id}> Releasing lock: #{lockId}"
        else
          if maxWaitSeconds?
            waited = Math.floor((Date.now()-start)/1000)
            if waited >= maxWaitSeconds
              dbLockLogger.debug () -> "---- <#{id}>  Failed to acquire lock after #{waited}s: #{lockId}"
              throw new jobQueueErrors.LockError("could not acquire db lock for lockId: #{lockId}")
          retry = true
    .then (result) ->
      if retry
        dbLockLogger.debug () -> "---- <#{id}>  Retrying lock attempt in #{retryIntervalSeconds}s: #{lockId}"
        Promise.delay(retryIntervalSeconds*1000)
        .then () ->
          attempt(attemptNum+1)
      else
        resolve(result)
    .catch (err) ->
      reject(err)
  attempt(1)


checkTask = (transaction, batchId, taskName) ->
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


getQueuedSubtask = (queueName) ->
  getQueueLockId(queueName)
  .then (queueLockId) ->
    withDbLock {lockId: queueLockId}, (transaction) ->
      currentTasksPromise = tables.jobQueue.taskHistory({transaction})
      .select('name')
      .select('status')
      .where(current: true)
      .then (tasks) ->
        _.indexBy(tasks, 'name')
      minTaskStepsPromise = transaction
      .select('task_name')
      .min('task_step AS task_step')
      .from () ->
        tables.jobQueue.currentSubtasks(transaction: @)
        .select('task_name')
        .select('task_step')
        .where(queue_name: queueName)
        .groupBy('task_name')
        .groupBy('task_step')
        .havingRaw('COUNT(finished IS NULL OR NULL) > 0')
        .as('task_steps')
      .groupBy('task_name')
      Promise.join currentTasksPromise, minTaskStepsPromise, (currentTasks, minTaskSteps=[]) ->
        possibleSteps = _.reject minTaskSteps, (taskStep) -> currentTasks[taskStep.task_name]?.status != 'running'
        if !possibleSteps.length
          return null
        tables.jobQueue.currentSubtasks({transaction})
        .min('id AS id')
        .where(status: 'queued')
        .whereRaw("COALESCE(ignore_until, '1970-01-01'::TIMESTAMP) <= NOW()")
        .whereIn('task_step', _.pluck(possibleSteps, 'task_step'))
      .then ([nextSubtask]=[]) ->
        if !nextSubtask?
          return null
        tables.jobQueue.currentSubtasks({transaction})
        .where(id: nextSubtask.id)
        .update
          status: 'preparing'
          preparing_started: transaction.raw('NOW()')
        .returning('*')
  .then (results) ->
    return results?[0]


retrySubtask = ({subtask, prefix, transaction, error, quiet}) ->
  dbs.ensureTransaction transaction, (transaction) ->
    loglevel = if quiet then 'debug' else 'info'
    retrySubtaskData = _.omit(subtask, 'id', 'enqueued', 'started', 'status', 'heartbeat', 'preparing_started')
    retrySubtaskData.retry_num += 1
    retrySubtaskData.ignore_until = dbs.get('main').raw("NOW() + ? * '1 minute'::INTERVAL", [subtask.retry_delay_minutes])
    checkTask(transaction, subtask.batch_id, subtask.task_name)
    .then (taskData) ->
      # need to make sure we don't continue to retry subtasks if the task has errored in some way
      if taskData == undefined
        logger[loglevel]("#{prefix} Can't retry subtask (task is no longer running) #{subtask.name}<#{summary(retrySubtaskData)}>, for batchId #{subtask.batch_id}: #{error}")
        return
      logger[loglevel]("#{prefix} Queuing retry ##{retrySubtaskData.retry_num}, #{subtask.name}<#{summary(retrySubtaskData)}>, for batchId #{subtask.batch_id}: #{error}")
      tables.jobQueue.currentSubtasks({transaction})
      .insert retrySubtaskData


handleSubtaskError = ({prefix, subtask, newStatus, hard, error}) ->
  logger.spawn("task:#{subtask.task_name}").debug () -> "#{prefix} error caught for subtask #{subtask.name}: #{JSON.stringify({errorType: newStatus, hard, error: error.toString()})}"
  dbs.transaction (transaction) ->
    Promise.try () ->
      if hard
        logger.error("#{prefix} Hard error executing subtask, #{subtask.name}<#{summary(subtask)}>(retry: ##{subtask.retry_num}), for batchId #{subtask.batch_id}: #{error}")
      else
        if subtask.retry_max_count? && subtask.retry_num >= subtask.retry_max_count
          hard = true
          newStatus = 'hard fail'
          error = "max retries exceeded due to: #{error}"
          logger.error("#{prefix} Hard error executing subtask, #{subtask.name}<#{summary(subtask)}>(retry: ##{subtask.retry_num}), for batchId #{subtask.batch_id}: #{error}")
        else
          retrySubtask({subtask, prefix, transaction, error, quiet: false})
    .then () ->
      tables.jobQueue.currentSubtasks({transaction})
      .where(id: subtask.id)
      .update
        status: newStatus
        finished: dbs.get('main').raw('NOW()')
      .returning('*')
    .then (updatedSubtask) ->
      # handle condition where currentSubtasks table gets cleared before the update -- it shouldn't happen under normal
      # conditions, but then again we're in an error handler so who knows what could be going on by the time we get here.
      # ideally we want to get a fresh copy of the data, but if it's gone, just use what we already had
      if !updatedSubtask?[0]?
        errorSubtask = _.clone(subtask)
        errorSubtask.status = newStatus
        errorSubtask.finished = dbs.get('main').raw('NOW()')
      else
        errorSubtask = updatedSubtask[0]
      errorSubtask.error = "#{error}"
      details = analyzeValue.getFullDetails(error)
      if details != errorSubtask.error
        errorSubtask.stack = details
      tables.jobQueue.subtaskErrorHistory({transaction})
      .insert errorSubtask
    .then () ->
      if hard
        Promise.join cancelTaskImpl(subtask.task_name, {newTaskStatus: 'hard fail', withPrejudice: false, transaction}), enqueueNotification
          payload:
            subject: 'subtask: hard fail'
            subtask: subtask
            error: "subtask: #{error}"


getQueueLockId = (queueName) ->
  tables.jobQueue.queueConfig()
  .select('lock_id')
  .where(name: queueName)
  .then (queueLockId) ->
    queueLockId[0].lock_id
getQueueLockId = memoize.promise(getQueueLockId, primitive: true)


sendLongTaskWarnings = (transaction=null) ->
  # warn about long-running tasks
  tables.jobQueue.taskHistory({transaction})
  .where(current: true)
  .whereNull('finished')
  .whereRaw("started + warn_timeout_minutes * INTERVAL '1 minute' < NOW()")
  .update(warn_timeout_minutes: dbs.raw('main', 'warn_timeout_minutes + 15'))
  .returning('*')
  .then (tasks=[]) ->
    for task in tasks
      logger.warn("Task from #{task.batch_id} has run over #{task.warn_timeout_minutes-15} minutes: #{task.name}")
    enqueueNotification
      payload:
        subject: 'task: long run warning'
        tasks: tasks
        error: 'tasks have been running for longer than expected'


killLongTasks = (transaction=null) ->
  # kill long-running tasks
  tables.jobQueue.taskHistory({transaction})
  .where(current: true)
  .whereNull('finished')
  .whereRaw("started + kill_timeout_minutes * INTERVAL '1 minute' < NOW()")
  .then (tasks=[]) ->
    cancelPromise = Promise.map tasks, (task) ->
      logger.warn("Task from #{task.batch_id} has run over #{task.kill_timeout_minutes} minutes (timeout): #{task.name}")
      cancelTaskImpl(task.name, {newTaskStatus: 'timeout', transaction})
    notificationPromise = Promise.try () ->
      enqueueNotification payload:
        subject: 'task: long run killed'
        tasks: tasks
        error: 'tasks have been running for longer than expected'
    Promise.join cancelPromise, notificationPromise


handleZombies = (transaction=null) ->
  # mark subtasks that should have been suicidal (but maybe disappeared instead) as zombies, and possibly cancel their tasks
  mainZombiesPromise = tables.jobQueue.currentSubtasks(transaction: transaction)
  .where(status: 'running')
  .where () ->
    @whereRaw("started + (#{config.JOB_QUEUE.SUBTASK_ZOMBIE_SLACK} + kill_timeout_minutes) * ('1 minute'::INTERVAL) < NOW()")
    @orWhereRaw("heartbeat + #{config.JOB_QUEUE.HEARTBEAT_MINUTES}*('1 minute'::INTERVAL)*3 < NOW()")
  preparedZombiesPromise = tables.jobQueue.currentSubtasks(transaction: transaction)
    .where(status: 'preparing')
    .whereRaw("preparing_started + #{config.JOB_QUEUE.SUBTASK_ZOMBIE_SLACK} * ('1 minute'::INTERVAL) < NOW()")
  Promise.join mainZombiesPromise, preparedZombiesPromise, (mainZombies=[], preparedZombies=[]) ->
    preparedIds = _.pluck(preparedZombies, 'id')
    subtasks = _.reject(mainZombies, (s) -> s.id in preparedIds).concat(preparedZombies)
    Promise.map subtasks, (subtask) ->
      handleSubtaskError({
        prefix: "<#{subtask.queue_name}-unknown>"
        subtask
        newStatus: 'zombie'
        hard: false
        error: 'zombie'
      })


handleSuccessfulTasks = (transaction=null) ->
  # mark running tasks with no unfinished or error subtasks as successful
  tables.jobQueue.taskHistory(transaction: transaction)
  .where
    current: true
    status: 'running'
  .whereNotExists () ->
    tables.jobQueue.currentSubtasks(transaction: this)
    .select(1)
    .whereRaw("#{tables.jobQueue.currentSubtasks.tableName}.task_name = #{tables.jobQueue.taskHistory.tableName}.name")
    .whereNull("#{tables.jobQueue.currentSubtasks.tableName}.finished")
  .update
    status: 'success'
    status_changed: dbs.get('main').raw('NOW()')


setFinishedTimestamps = (transaction=null) ->
  # set the correct 'finished' value for tasks based on finished timestamps for their subtasks
  tables.jobQueue.taskHistory(transaction: transaction)
  .where(current: true)
  .whereNotIn('status', ['preparing', 'running'])
  .update 'finished', () ->
    # an optimized query to get the max finished value over all subtasks for the task, using an index
    tables.jobQueue.currentSubtasks(transaction: this)
    .select('finished')
    .whereRaw("#{tables.jobQueue.currentSubtasks.tableName}.task_name = #{tables.jobQueue.taskHistory.tableName}.name")
    .orderBy("#{tables.jobQueue.currentSubtasks.tableName}.task_name")
    .orderByRaw("finished DESC NULLS LAST")
    .limit(1)


_updateTaskCountsImpl = (transaction, taskCriteria) ->
  tables.jobQueue.currentSubtasks({transaction})
  .select(dbs.raw('main', "COUNT(*) AS subtasks_created"))
  .select(dbs.raw('main', "COUNT(finished IS NULL AND status != 'preparing' AND status != 'running' OR NULL) AS subtasks_queued"))
  .select(dbs.raw('main', "COUNT(status = 'preparing' OR NULL) AS subtasks_preparing"))
  .select(dbs.raw('main', "COUNT(status = 'running' OR NULL) AS subtasks_running"))
  .select(dbs.raw('main', "COUNT(status = 'soft fail' OR NULL) AS subtasks_soft_failed"))
  .select(dbs.raw('main', "COUNT(status = 'hard fail' OR NULL) AS subtasks_hard_failed"))
  .select(dbs.raw('main', "COUNT(status = 'infrastructure fail' OR NULL) AS subtasks_infrastructure_failed"))
  .select(dbs.raw('main', "COUNT(status = 'canceled' OR NULL) AS subtasks_canceled"))
  .select(dbs.raw('main', "COUNT(status = 'timeout' OR NULL) AS subtasks_timeout"))
  .select(dbs.raw('main', "COUNT(status = 'zombie' OR NULL) AS subtasks_zombie"))
  .select(dbs.raw('main', "COUNT(finished) AS subtasks_finished"))
  .select(dbs.raw('main', "COUNT(status = 'success' OR NULL) AS subtasks_succeeded"))
  .select(dbs.raw('main', "COUNT(status NOT IN ('queued', 'preparing', 'running', 'success', 'canceled') OR NULL) AS subtasks_failed"))
  .where({task_name: taskCriteria.name, batch_id: taskCriteria.batch_id})
  .then ([counts]) ->
    tables.jobQueue.taskHistory({transaction})
    .where(taskCriteria)
    .update(counts)

updateTaskCounts = (transaction) ->
  tables.jobQueue.taskHistory({transaction})
  .select('name', 'batch_id')
  .whereNull('finished')
  .orWhereRaw("finished >= (NOW() - '1 day'::INTERVAL)")
  .then (tasks) ->
    Promise.map tasks, (taskCriteria) ->
      _updateTaskCountsImpl(transaction, taskCriteria)


runWorkerImpl = (queueName, prefix, quit) ->
  logger.spawn("queue:#{queueName}").debug () -> "#{prefix} Getting next subtask..."
  getQueuedSubtask(queueName)
  .then (subtask) ->
    nextIteration = runWorkerImpl.bind(null, queueName, prefix, quit)
    if subtask?
      logger.spawn("task:#{subtask.task_name}").debug () ->  "#{prefix} Preparing to execute subtask: #{subtask.name}<#{summary(subtask)}>(retry: ##{subtask.retry_num}), for batchId #{subtask.batch_id}"
      return executeSubtask(subtask, prefix)
      .then nextIteration
    else
      logger.spawn("queue:#{queueName}").debug () -> "#{prefix} No subtask returned."

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


executeSubtask = (subtask, prefix) ->
  heartbeat = () ->
    Promise.resolve()
    .cancellable()
    .then () ->
      Promise.delay(config.JOB_QUEUE.HEARTBEAT_MINUTES*60*1000)
    .then () ->
      tables.jobQueue.currentSubtasks()
      .where(id: subtask.id)
      .update(heartbeat: dbs.get('main').raw('NOW()'))
    .then () ->
      heartbeat()
    .catch Promise.CancellationError, (err) ->
      logger.spawn("task:#{subtask.task_name}").debug () -> "heartbeat cancelled"
    .catch (err) ->
      logger.spawn("task:#{subtask.task_name}").error () -> "heartbeat error: #{analyzeValue.getFullDetails(err)}"
      throw err
  heartbeatPromise = heartbeat()
  getSubtaskConfig(subtask.name, subtask.task_name)
  .then (subtaskConfig) ->
    subtaskConfig.data ?= {}
    _.defaultsDeep(subtaskConfig, subtask)
    delete subtaskConfig.active
    subtask = _.clone(subtaskConfig)
    tables.jobQueue.currentSubtasks()
    .where(id: subtask.id)
    .update _.extend subtaskConfig,
      status: 'running'
      started: dbs.get('main').raw('NOW()')
      heartbeat: dbs.get('main').raw('NOW()')
      preparing_started: null
  .then () ->
    TaskImplementation.getTaskCode(subtask.task_name)
  .then (taskImpl) ->
    logger.info "#{prefix} Executing subtask: #{subtask.name}<#{summary(subtask)}>(retry: ##{subtask.retry_num}), for batchId #{subtask.batch_id}"
    subtaskPromise = taskImpl.executeSubtask(subtask, prefix)
    .cancellable()
    .then () ->
      logger.spawn("task:#{subtask.task_name}").debug () -> "#{prefix} finished subtask #{subtask.name}"
      tables.jobQueue.currentSubtasks()
      .where(id: subtask.id)
      .update
        status: 'success'
        finished: dbs.get('main').raw('NOW()')
    if subtask.kill_timeout_minutes
      subtaskPromise = subtaskPromise
      .timeout(subtask.kill_timeout_minutes*60*1000)
      .catch Promise.TimeoutError, (err) ->
        handleSubtaskError({prefix, subtask, newStatus: 'timeout', hard: false, error: 'timeout'})
    if subtask.warn_timeout_minutes
      warnTimeout = null
      doNotification = (minutes) ->
        logger.warn("Subtask from #{subtask.batch_id} has run over #{minutes} minutes: #{subtask.name}")
        warnTimeout = setTimeout(doNotification, 10*60*1000, minutes+10)
        enqueueNotification payload:
          subject: 'subtask: long run warning'
          subtask: subtask
          error: "subtask has been running for longer than #{minutes} minutes"
      warnTimeout = setTimeout(doNotification, subtask.warn_timeout_minutes*60*1000, subtask.warn_timeout_minutes)
      subtaskPromise = subtaskPromise
      .finally () ->
        clearTimeout(warnTimeout)
    return subtaskPromise
  .then () ->
    logger.spawn("task:#{subtask.task_name}").debug () -> "#{prefix} subtask #{subtask.name} updated with success status"
  .catch jobQueueErrors.SoftFail, (err) ->
    handleSubtaskError({prefix, subtask, newStatus: 'soft fail', hard: false, error: err})
  .catch jobQueueErrors.HardFail, (err) ->
    handleSubtaskError({prefix, subtask, newStatus: 'hard fail', hard: true, error: err})
  .catch errorHandlingUtils.PartiallyHandledError, (err) ->
    handleSubtaskError({prefix, subtask, newStatus: 'infrastructure fail', hard: true, error: err})
  .catch errorHandlingUtils.isUnhandled, (err) ->
    logger.error("Unexpected error caught during job execution: #{analyzeValue.getFullDetails(err)}")
    handleSubtaskError({prefix, subtask, newStatus: 'infrastructure fail', hard: true, error: err})
  .catch (err) -> # if we make it here, then we probably can't rely on the db for error reporting
    logger.error("#{prefix} Error caught while handling errors; major db problem likely!  subtask: #{subtask.name}")
    enqueueNotification payload:
      subject: 'major db interaction problem'
      subtask: subtask
      error: err
    throw err
  .finally () ->
    heartbeatPromise.cancel()


cancelTaskImpl = (taskName, opts={}) ->
  {transaction, newTaskStatus, withPrejudice} = opts
  newTaskStatus ?= 'canceled'
  # note that this doesn't cancel subtasks that are already running; there's no easy way to do that except within the
  # worker that's executing that subtask, and we're not going to make that worker poll to watch for a cancel message
  logger.spawn("cancels").debug("Cancelling task: #{taskName}, status:#{newTaskStatus}, withPrejudice:#{withPrejudice}")

  dbs.ensureTransaction transaction, (trx) ->
    tables.jobQueue.taskHistory({transaction: trx})
    .where
      current: true
      name: taskName
    .whereNull('finished')
    .returning('batch_id')
    .update
      status: newTaskStatus
      status_changed: dbs.get('main').raw('NOW()')
      finished: dbs.get('main').raw('NOW()')
    .then ([batch_id]) ->
      if !batch_id
        logger.spawn("task:#{taskName}").debug () -> "No unfinished #{taskName} task to cancel."
        return
      subtaskCancelQuery = tables.jobQueue.currentSubtasks({transaction: trx})
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
        _updateTaskCountsImpl trx,
          name: taskName
          batch_id: batch_id
        .then () ->
          logger.spawn("task:#{taskName}").debug () -> "Canceled #{count} subtasks of #{taskName}."

# non db portion of queueSubtask
buildQueueSubtaskDatas = ({subtask, manualData, replace}) ->
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

  {
    subtaskData
    mergeData
  }

# non db portion of queuePaginatedSubtask
buildQueuePaginatedSubtaskDatas = ({totalOrList, maxPage, mergeData}) ->
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
    subtasksQueued += 1
    countHandled += datum.count
    data.push(datum)
  data


getSubtaskConfig = (subtaskName, taskName, transaction) ->
  tables.jobQueue.subtaskConfig(transaction: transaction)
  .where
    name: subtaskName
    task_name: taskName
  .then (subtasks) ->
    if !subtasks?.length
      throw new Error("specified subtask not found: #{taskName}/#{subtaskName}")
    return subtasks[0]


module.exports = {
  getPossiblyReadyTasks
  summary
  withDbLock
  checkTask
  handleSubtaskError
  getQueueLockId
  sendLongTaskWarnings
  killLongTasks
  handleZombies
  handleSuccessfulTasks
  setFinishedTimestamps
  updateTaskCounts
  runWorkerImpl
  cancelTaskImpl
  executeSubtask
  enqueueNotification
  buildQueueSubtaskDatas
  buildQueuePaginatedSubtaskDatas
  getSubtaskConfig
  retrySubtask
}
