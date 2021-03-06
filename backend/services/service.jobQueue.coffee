require '../config/promisify'
Promise = require 'bluebird'
sqlHelpers = require '../utils/util.sql.helpers'
logger = require('../config/logger').spawn('jobQueue')
_ = require 'lodash'
tables = require '../config/tables'
cluster = require 'cluster'
config = require '../config/config'
keystore = require './service.keystore'
TaskImplementation = require '../tasks/util.taskImplementation'
dbs = require '../config/dbs'
jobQueueErrors = require '../utils/errors/util.error.jobQueue'
internals = require './service.jobQueue.internals'
moment = require 'moment'
tz = require '../config/tz'


# to understand at a high level most of what is going on in this code and how to write a task to be utilized by this
# module, go to https://realtymaps.atlassian.net/wiki/display/DN/Job+queue%3A+the+developer+guide

MAINTENANCE_TIMESTAMP = 'job queue maintenance timestamp'


queueReadyTasks = (opts={}) -> Promise.try () ->
  batchId = (Date.now()).toString(36)
  internals.withDbLock {lockId: config.JOB_QUEUE.SCHEDULING_LOCK_ID, maxWaitSeconds: 0}, (transaction) ->
    internals.getPossiblyReadyTasks(transaction)
    .then (possiblyTasks=[]) ->
      result = []
      Promise.each possiblyTasks, (task) ->
        # prevent race condition where we start 2 mutually-exclusive tasks at the same time
        for blockingTaskName in task.blocked_by_tasks
          if blockingTaskName in result
            # getPossiblyReadyTasks() orders results in order of prior start timestamp (ascending), which ensures this
            # logic will at worst round-robin between 2 mutually exclusive tasks; one can't starve another
            return
        # allow for task-specific logic to say it still isn't ready to run
        TaskImplementation.getTaskCode(task.name)
        .then (taskImpl) ->
          taskImpl.ready()
        .then (isReady) ->
          if !isReady
            return
          queueTask(transaction, batchId, task, '<scheduler>')
          .catch jobQueueErrors.TaskNotImplemented, (err) ->
            logger.error "#{err}"
            if opts.dieOnMissingTask
              throw err
        .then () ->
          result.push(task.name)
      .then () ->
        result


queueManualTask = (taskName, initiator) ->
  if !taskName
    throw new jobQueueErrors.TaskStartError('Task name required!')
  internals.withDbLock {lockId: config.JOB_QUEUE.SCHEDULING_LOCK_ID, maxWaitSeconds: 20, retryIntervalSeconds: 5}, (transaction) ->
    # need to be sure it's not already running
    tables.jobQueue.taskHistory({transaction})
    .select()
    .where
      current: true
      name: taskName
    .then (task) ->
      if task?.length && !task[0].finished
        started = moment.utc(task[0].started).utcOffset(tz.MOMENT_UTC_OFFSET).format('ddd, MMM DD, YYYY [at] hh:mma')
        throw new jobQueueErrors.TaskStartError("Refusing to queue task #{taskName}; another instance is currently #{task[0].status}, started #{started} by #{task[0].initiator}")
    .then () ->
      tables.jobQueue.taskConfig({transaction})
      .select()
      .where(name: taskName)
      .then (result) ->
        if result.length == 0
          throw new jobQueueErrors.TaskStartError("Task not found: #{taskName}")

        taskConfig = result[0]
        if taskConfig.blocked_by_tasks.length
          # need to be sure there isn't another running task that blocks this task
          taskBlockPromise = tables.jobQueue.taskHistory({transaction})
          .select('name')
          .where(current: true)
          .whereNull('finished')
          .whereIn('name', taskConfig.blocked_by_tasks)
          .then (blockingTasks) ->
            if blockingTasks.length
              throw new jobQueueErrors.TaskStartError("Refusing to queue task #{taskName} due to #{blockingTasks.length} blocking tasks: #{_.pluck(blockingTasks, 'name').join(', ')}")
        else
          taskBlockPromise = Promise.resolve()

        if taskConfig.blocked_by_locks.length
          # need to be sure there isn't a lock set that prevents this task from running
          lockBlockPromise = tables.config.keystore({transaction})
          .select('key')
          .where(namespace: 'locks')
          .whereIn('key', taskConfig.blocked_by_locks)
          .whereRaw("value::TEXT = 'true'")
          .then (blockingLocks) ->
            if blockingLocks.length
              throw new jobQueueErrors.TaskStartError("Refusing to queue task #{taskName} due to #{blockingLocks.length} blocking locks: #{_.pluck(blockingLocks, 'key').join(', ')}")
        else
          lockBlockPromise = Promise.resolve()

        Promise.join taskBlockPromise, lockBlockPromise, () ->
          return taskConfig

    .then (taskConfig) ->
      batchId = (Date.now()).toString(36)
      logger.info "Queueing #{taskName} for #{initiator} using batchId #{batchId}"
      queueTask(transaction, batchId, taskConfig, initiator)


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
      blocked_by_tasks: sqlHelpers.safeJsonArray(task.blocked_by_tasks)
      blocked_by_locks: sqlHelpers.safeJsonArray(task.blocked_by_locks)
  .then () -> # clear out any subtasks for prior runs of this task
    tables.jobQueue.currentSubtasks(transaction: transaction)
    .where(task_name: task.name)
    .whereNot(batch_id: batchId)
    .delete()
  .then () ->  # now to enqueue (initial) subtasks
    TaskImplementation.getTaskCode(task.name)
    .then (taskImpl) ->
      taskImpl.initialize(transaction, batchId, task)
  .then (count) ->
    if count == 0
      throw new Error("0 subtasks enqueued for #{@taskName}")
    tables.jobQueue.taskHistory(transaction: transaction)
    .where
      name: task.name
      current: true
    .update
      subtasks_created: count
      status: 'running'
      status_changed: dbs.get('main').raw('NOW()')

queueSubtasks = ({transaction, batchId, subtasks, concurrency, stepNumOffset}) -> Promise.try () ->
  if !subtasks?.length
    return 0
  internals.checkTask(transaction, batchId, subtasks[0].task_name)
  .then (taskData) ->
    # need to make sure we don't continue to queue subtasks if the task has errored in some way
    if taskData == undefined
      # return an array indicating we queued 0 subtasks
      logger.spawn("task:#{subtasks[0].task_name}").debug () -> "Refusing to queue subtasks (parent task might have terminated): #{_.pluck(subtasks, 'name').join(', ')}"
      return [0]
    Promise.all _.map subtasks, (subtask) -> # can't use bind here because it passes in unwanted params
      queueSubtask({transaction, batchId, taskData, subtask, concurrency, stepNumOffset})
  .then (counts) ->
    return _.reduce counts, (sum, count) -> sum+count

# convenience function to get another subtask config and then enqueue it based on the current subtask
queueSubsequentSubtask = ({transaction, subtask, laterSubtaskName, manualData, replace, concurrency, stepNumOffset}) ->
  subtaskName = "#{subtask.task_name}_#{laterSubtaskName}"
  internals.getSubtaskConfig(subtaskName, subtask.task_name, transaction)
  .then (laterSubtask) ->
    queueSubtask({transaction, batchId: subtask.batch_id, subtask: laterSubtask, manualData, replace, concurrency, stepNumOffset})

queueSubtask = ({transaction, batchId, taskData, subtask, manualData, replace, concurrency, stepNumOffset}) -> Promise.try () ->
  if !subtask.active
    logger.spawn("task:#{subtask.task_name}").debug () -> "Refusing to queue inactive subtask for batchId #{batchId}: #{subtask.name}"
    return 0
  {subtaskData, mergeData} = internals.buildQueueSubtaskDatas {subtask, manualData, replace}
  # maybe we've already gotten the data and checked to be sure the task is still running
  if taskData != undefined
    taskDataPromise = Promise.resolve(taskData)
  else
    taskDataPromise = internals.checkTask(transaction, batchId, subtask.task_name)
  taskDataPromise
  .then (freshTaskData) ->
    # need to make sure we don't queue the subtask if the task has errored in some way
    if freshTaskData == undefined
      # return 0 to indicate we queued 0 subtasks
      logger.spawn("task:#{subtask.task_name}").debug () -> "Refusing to queue subtask for batchId #{batchId} (parent task might have terminated): #{subtask.name}"
      return 0
    summary = if subtaskData?.length? then "#{subtask.name}[#{subtaskData.length}](batchId:#{batchId})" else internals.summary(subtask)
    logger.spawn("task:#{subtask.task_name}").debug () -> "Queueing subtask: #{summary}"
    if _.isArray subtaskData    # an array for data means to create multiple subtasks, one for each element of data
      Promise.map subtaskData, (data, index) ->
        singleSubtask = _.clone(subtask)
        delete singleSubtask.active
        if concurrency
          singleSubtask.step_num += Math.floor(index/concurrency)
        if stepNumOffset
          singleSubtask.step_num += stepNumOffset
        singleSubtask.data = data
        if mergeData?
          _.extend(singleSubtask.data, mergeData)
        singleSubtask.task_data = freshTaskData
        singleSubtask.task_step = "#{singleSubtask.task_name}_#{('0000000'+(singleSubtask.step_num||'FINAL__')).slice(-7)}"
        singleSubtask.batch_id = batchId
        tables.jobQueue.currentSubtasks(transaction: transaction)
        .insert singleSubtask
      .then () ->
        return subtaskData.length
    else
      singleSubtask = _.clone(subtask)
      delete singleSubtask.active
      if stepNumOffset
        singleSubtask.step_num += stepNumOffset
      singleSubtask.data = subtaskData
      singleSubtask.task_data = freshTaskData
      singleSubtask.task_step = "#{subtask.task_name}_#{('0000000'+(singleSubtask.step_num||'FINAL__')).slice(-7)}"
      singleSubtask.batch_id = batchId
      tables.jobQueue.currentSubtasks(transaction: transaction)
      .insert singleSubtask
      .then () ->
        return 1

cancelTask = internals.cancelTaskImpl


cancelAllRunningTasks = (forget, status='canceled', withPrejudice=false) ->
  logger.spawn("manual").debug("Canceling all tasks -- forget:#{forget}, status:#{status}, withPrejudice:#{withPrejudice}")
  dbs.transaction (transaction) ->
    tables.jobQueue.taskHistory({transaction})
    .where
      current: true
    .whereNull('finished')
    .map (task) ->
      cancelTask(task.name, {newTaskStatus: status, withPrejudice, transaction})
      .then () ->
        if forget
          tables.jobQueue.taskHistory({transaction})
          .where
            name: task.name
            current: true
          .delete()


# convenience helper for dev/troubleshooting
requeueManualTask = (taskName, initiator, withPrejudice=false) ->
  logger.spawn("manual").debug("Requeuing manual task: #{taskName}, for initiator: #{initiator}")
  cancelTask(taskName, {newTaskStatus: 'canceled', withPrejudice})
  .then () ->
    queueManualTask(taskName, initiator)


doMaintenance = () ->
  maintenanceLogger = logger.spawn("maintenance")
  maintenanceLogger.debug('Doing maintenance...')
  internals.withDbLock {lockId: config.JOB_QUEUE.MAINTENANCE_LOCK_ID, maxWaitSeconds: 0}, (transaction) ->
    maintenanceLogger.debug('Getting last maintenance timestamp...')
    keystore.getValue(MAINTENANCE_TIMESTAMP, defaultValue: 0)
    .then (timestamp) ->
      if Date.now() - timestamp < config.JOB_QUEUE.MAINTENANCE_WINDOW
        maintenanceLogger.debug('Skipping maintenance.')
        return
      Promise.try () ->
        maintenanceLogger.debug('internals.handleSuccessfulTasks...')
        internals.handleSuccessfulTasks(transaction)
      .then () ->
        maintenanceLogger.debug('internals.setFinishedTimestamps...')
        internals.setFinishedTimestamps(transaction)
      .then () ->
        maintenanceLogger.debug('internals.sendLongTaskWarnings...')
        internals.sendLongTaskWarnings(transaction)
      .then () ->
        maintenanceLogger.debug('internals.killLongTasks...')
        internals.killLongTasks(transaction)
      .then () ->
        maintenanceLogger.debug('internals.handleZombies...')
        internals.handleZombies(transaction)
      .then () ->
        maintenanceLogger.debug('internals.setFinishedTimestamps...')
        internals.setFinishedTimestamps(transaction)
      .then () ->
        maintenanceLogger.debug('internals.updateTaskCounts...')
        internals.updateTaskCounts(transaction)
      .then () ->
        maintenanceLogger.debug('Setting last maintenance timestamp...')
        keystore.setValue(MAINTENANCE_TIMESTAMP, Date.now())

getQueueNeeds = () ->
  queueNeeds = {}
  queueConfigs = {}
  dbs.transaction (transaction) ->
    queueConfigPromise = tables.jobQueue.queueConfig({transaction})
    .select('*')
    .then (_queueConfigs) ->
      for queueConfig in _queueConfigs
        queueNeeds[queueConfig.name] = 0
        queueConfigs[queueConfig.name] = queueConfig
    activeStepsPromise = tables.jobQueue.taskHistory({transaction})
    .select('name')
    .where(current: true)
    .whereNull('finished')
    .map (taskConfig) ->
      tables.jobQueue.currentSubtasks({transaction})
      .select('task_step', 'queue_name')
      .select(dbs.raw('main', "COUNT(finished IS NULL AND (ignore_until IS NULL OR ignore_until < NOW()) OR NULL)::INTEGER AS needs"))
      .where('task_name', taskConfig.name)
      .groupBy('task_step')
      .groupBy('queue_name')
      .orderBy('task_step')
      .havingRaw('BOOL_AND(finished IS NOT NULL) = FALSE')
      .limit(1)
    Promise.join activeStepsPromise, queueConfigPromise, (activeSteps, dummy) ->
      return activeSteps
  .then (activeSteps) ->
    for [activeStep] in activeSteps
      if !activeStep
        continue
      if !queueConfigs[activeStep.queue_name]?.active
        # any task running on an inactive queue (or a queue without config) can be ignored
        continue
      queueNeeds[activeStep.queue_name] += activeStep.needs
    result = []
    for name of queueConfigs
      needs = 0
      if queueNeeds[name] > 0
        needs = queueNeeds[name] * queueConfigs[name].priority_factor
        needs /= (queueConfigs[name].subtasks_per_process * queueConfigs[name].processes_per_dyno)
        needs = Math.ceil(needs)
      result.push(name: name, quantity: needs)
    return result

# convenience function to get another subtask config and then enqueue it (paginated) based on the current subtask
queueSubsequentPaginatedSubtask = ({transaction, subtask, totalOrList, maxPage, laterSubtaskName, mergeData, concurrency, stepNumOffset}) ->
  internals.getSubtaskConfig("#{subtask.task_name}_#{laterSubtaskName}", subtask.task_name, transaction)
  .then (laterSubtask) ->
    queuePaginatedSubtask({transaction, batchId: subtask.batch_id, totalOrList, maxPage, subtask: laterSubtask, mergeData, concurrency, stepNumOffset})

queuePaginatedSubtask = ({transaction, batchId, taskData, totalOrList, maxPage, subtask, mergeData, concurrency, stepNumOffset}) -> Promise.try () ->
  data = internals.buildQueuePaginatedSubtaskDatas {totalOrList, maxPage, mergeData}
  if !data
    return
  queueSubtask({transaction, batchId, taskData, subtask, manualData: data, concurrency, stepNumOffset})

runWorker = (queueName, id, quit=false) ->
  if id?
    processId = "-#{id}"
  else
    processId = ""
  if cluster.worker?
    prefix = "<#{queueName}-#{cluster.worker.id}#{processId}>"
  else
    prefix = "<#{queueName}#{processId}>"
  logger.spawn("queue:#{queueName}").debug () -> "#{prefix} worker starting..."
  internals.runWorkerImpl(queueName, prefix, quit)


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
  doMaintenance
  getQueueNeeds
  queuePaginatedSubtask
  queueSubsequentPaginatedSubtask
  runWorker
  getLastTaskStartTime
  cancelAllRunningTasks
  executeSubtask: internals.executeSubtask
  retrySubtask: internals.retrySubtask
}
