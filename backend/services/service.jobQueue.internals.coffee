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


summary = (subtask) ->
  JSON.stringify(_.omit(subtask.data,['values', 'ids']))


withDbLock = (lockId, handler) ->
  id = cluster.worker?.id ? 'X'
  dbs.transaction 'main', (transaction) ->
    logger.spawn('dbLock').debug () -> "---- <#{id}>   Getting lock: #{lockId}"
    transaction
    .select(dbs.get('main').raw("pg_advisory_xact_lock(#{config.JOB_QUEUE.LOCK_KEY}, #{lockId})"))
    .then () ->
      logger.spawn('dbLock').debug () -> "---- <#{id}>  Acquired lock: #{lockId}"
      handler(transaction)
    .finally () ->
      logger.spawn('dbLock').debug () -> "---- <#{id}> Releasing lock: #{lockId}"


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

# TODO: should this be rewritten to use a query built by knex instead of a stored proc?
getQueuedSubtask = (queueName) ->
  getQueueLockId(queueName)
  .then (queueLockId) ->
    withDbLock queueLockId, (transaction) ->
      transaction
      .select('*')
      .from(transaction.raw('jq_get_next_subtask(?)', [queueName]))
      .then (results) ->
        if !results?[0]?.id?
          return null
        else
          return results[0]


handleSubtaskError = ({prefix, subtask, status, hard, error}) ->
  logger.spawn("task:#{subtask.task_name}").debug () -> "#{prefix} error caught for subtask #{subtask.name}: #{JSON.stringify({errorType: status, hard, error: error.toString()})}"
  Promise.try () ->
    if hard
      logger.error("#{prefix} Hard error executing subtask for batchId #{subtask.batch_id}, #{subtask.name}<#{summary(subtask)}>: #{error}")
    else
      if subtask.retry_max_count? && subtask.retry_num >= subtask.retry_max_count
        if subtask.hard_fail_after_retries
          hard = true
          status = 'hard fail'
          error = "max retries exceeded due to: #{error}"
          logger.error("#{prefix} Hard error executing subtask for batchId #{subtask.batch_id}, #{subtask.name}<#{summary(subtask)}>: #{error}")
        else
          logger.warn("#{prefix} Soft error executing subtask for batchId #{subtask.batch_id}, #{subtask.name}<#{summary(subtask)}>: #{error}")
      else
        retrySubtask = _.omit(subtask, 'id', 'enqueued', 'started', 'status')
        retrySubtask.retry_num += 1
        retrySubtask.ignore_until = dbs.get('main').raw("NOW() + ? * INTERVAL '1 second'", [subtask.retry_delay_seconds])
        checkTask(null, subtask.batch_id, subtask.task_name)
        .then (taskData) ->
          # need to make sure we don't continue to retry subtasks if the task has errored in some way
          if taskData == undefined
            logger.info("#{prefix} Can't retry subtask (task is no longer running) for batchId #{subtask.batch_id}, #{subtask.name}<#{summary(retrySubtask)}>: #{error}")
            return
          logger.info("#{prefix} Queuing retry subtask for batchId #{subtask.batch_id}, #{subtask.name}<#{summary(retrySubtask)}>: #{error}")
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
      Promise.join cancelTaskImpl(subtask.task_name, 'hard fail'), enqueueNotification
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
  tables.jobQueue.taskHistory(transaction: transaction)
  .whereNull('finished')
  .whereNotNull('warn_timeout_minutes')
  .where(current: true)
  .whereRaw("started + warn_timeout_minutes * INTERVAL '1 minute' < NOW()")
  .then (tasks=[]) ->
    enqueueNotification
      payload:
        subject: 'task: long run warning'
        tasks: tasks
        error: 'tasks have been running for longer than expected'


killLongTasks = (transaction=null) ->
  # kill long-running tasks
  tables.jobQueue.taskHistory(transaction: transaction)
  .whereNull('finished')
  .whereNotNull('kill_timeout_minutes')
  .where(current: true)
  .whereRaw("started + kill_timeout_minutes * INTERVAL '1 minute' < NOW()")
  .then (tasks=[]) ->
    cancelPromise = Promise.map tasks, (task) ->
      logger.warn("Task for batchId #{task.batch_id} has timed out: #{task.name}")
      cancelTaskImpl(task.name, 'timeout')
    notificationPromise = enqueueNotification payload:
      subject: 'task: long run killed'
      tasks: tasks
      error: 'tasks have been running for longer than expected'
    Promise.join cancelPromise, notificationPromise


handleZombies = (transaction=null) ->
  # mark subtasks that should have been suicidal (but maybe disappeared instead) as zombies, and possibly cancel their tasks
  tables.jobQueue.currentSubtasks(transaction: transaction)
  .whereNull('finished')
  .whereNotNull('started')
  .whereNotNull('kill_timeout_seconds')
  .whereRaw("started + #{config.JOB_QUEUE.SUBTASK_ZOMBIE_SLACK} + kill_timeout_seconds * INTERVAL '1 second' < NOW()")
  .orWhere () ->
    @whereRaw("preparing_started + #{config.JOB_QUEUE.SUBTASK_ZOMBIE_SLACK} + INTERVAL '1 second' < NOW()")
    @where(status: 'preparing')
  .then (subtasks=[]) ->
    Promise.map subtasks, (subtask) ->
      handleSubtaskError({
        prefix: "<#{subtask.queue_name}-unknown>"
        subtask
        status: 'zombie'
        hard: subtask.hard_fail_zombies
        error: 'zombie'
      })


handleSuccessfulTasks = (transaction=null) ->
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
        this.where "#{tables.jobQueue.currentSubtasks.tableName}.status", 'timeout'
        this.where "#{tables.jobQueue.currentSubtasks.tableName}.hard_fail_timeouts", true
      .orWhere () ->
        this.where "#{tables.jobQueue.currentSubtasks.tableName}.status", 'zombie'
        this.where "#{tables.jobQueue.currentSubtasks.tableName}.hard_fail_zombies", true
  .update
    status: 'success'
    status_changed: dbs.get('main').raw('NOW()')


setFinishedTimestamps = (transaction=null) ->
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


updateTaskCounts = (transaction) ->
  transaction.select(dbs.get('main').raw('jq_update_task_counts()'))


runWorkerImpl = (queueName, prefix, quit) ->
  logger.spawn("queue:#{queueName}").debug () -> "#{prefix} Getting next subtask..."
  getQueuedSubtask(queueName)
  .then (subtask) ->
    nextIteration = runWorkerImpl.bind(null, queueName, prefix, quit)
    if subtask?
      logger.info "#{prefix} Executing subtask for batchId #{subtask.batch_id}: #{subtask.name}<#{summary(subtask)}>(retry: #{subtask.retry_num})"
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
        handleSubtaskError({prefix, subtask, status: 'timeout', hard: subtask.hard_fail_timeouts, error: 'timeout'})
    if subtask.warn_timeout_seconds
      doNotification = () ->
        enqueueNotification payload:
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
  .catch jobQueueErrors.SoftFail, (err) ->
    handleSubtaskError({prefix, subtask, status: 'soft fail', hard: false, error: err})
  .catch jobQueueErrors.HardFail, (err) ->
    handleSubtaskError({prefix, subtask, status: 'hard fail', hard: true, error: err})
  .catch errorHandlingUtils.PartiallyHandledError, (err) ->
    handleSubtaskError({prefix, subtask, status: 'infrastructure fail', hard: true, error: err})
  .catch errorHandlingUtils.isUnhandled, (err) ->
    logger.error("Unexpected error caught during job execution: #{analyzeValue.getSimpleDetails(err)}")
    handleSubtaskError({prefix, subtask, status: 'infrastructure fail', hard: true, error: err})
  .catch (err) -> # if we make it here, then we probably can't rely on the db for error reporting
    logger.error("#{prefix} Error caught while handling errors; major db problem likely!  subtask: #{subtask.name}")
    enqueueNotification payload:
      subject: 'major db interaction problem'
      subtask: subtask
      error: err
    throw err


cancelTaskImpl = (taskName, status='canceled', withPrejudice=false) ->
# note that this doesn't cancel subtasks that are already running; there's no easy way to do that except within the
# worker that's executing that subtask, and we're not going to make that worker poll to watch for a cancel message
  logger.spawn("cancels").debug("Cancelling task: #{taskName}, status:#{status}, withPrejudice:#{withPrejudice}")
  dbs.transaction 'main', (transaction) ->
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

module.exports = {
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
}
