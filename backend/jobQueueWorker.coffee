config = require './config/config'

logger = require './config/logger'
cluster = require './config/cluster'
tables = require './config/tables'
jobQueue = require './utils/util.jobQueue'
# just to make sure we can run the hirefire backup if necessary (in case the web process is down)
require './routes/route.hirefire'


# catch all uncaught exceptions
process.on 'uncaughtException', (err) ->
  logger.error 'Something very bad happened: ', err.message
  logger.error err.stack || err
  process.exit 1  # because now, you are in unpredictable state!

queueName = process.argv[2] || ''
tables.jobQueue.queueConfig()
.select('*')
.where(name: queueName)
.then (queues) ->
  if !queues || !queues.length
    logger.error "Can't find config for queue: #{queueName}"
    process.exit(2)
  queue = queues[0]
  if !queue.active
    logger.error "Queue shouldn't be active: #{queueName}"
    process.exit(3)
  
  cluster queueName, queue.processes_per_dyno, () ->
    workers = for i in [1..queue.subtasks_per_process]
      jobQueue.runWorker(queueName, i)
    Promise.all workers

.catch (err) ->
  logger.error "Error processing job queue (#{queueName}):"
  logger.error "#{err.stack||err}"
