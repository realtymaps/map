config = require './config/config'

logger = require './config/logger'
cluster = require './config/cluster'
tables = require './config/tables'
jobQueue = require './utils/util.jobQueue'
# just to make sure we can run the hirefire backup if necessary (in case the web process is down)
require './routes/route.hirefire'
dbs = require "./config/dbs"


_doExit = (exitCode) ->
  dbs.shutdown()
  process.exit(exitCode)
  

# catch all uncaught exceptions
process.on 'uncaughtException', (err) ->
  logger.error 'Something very bad happened!!!'
  logger.error err.stack || err
  _doExit(1)  # because now, you are in unpredictable state!

queueName = process.argv[2]
quit = process.argv[3]?.toLowerCase() == 'quit'
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
    _doExit(3)
  
  clusterOpts =
    workerCount: queue.processes_per_dyno
    allowQuit: quit
  cluster queueName, clusterOpts, () ->
    workers = []
    for i in [1..queue.subtasks_per_process]
      workers.push jobQueue.runWorker(queueName, i, quit)
    Promise.all(workers)
    .then () ->
      if quit
        logger.debug("All workers done; quitting.")
        _doExit(0)
.catch (err) ->
  logger.error "Error processing job queue (#{queueName}):"
  logger.error "#{err.stack||err}"
  _doExit(100)
