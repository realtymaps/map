logger = require './config/logger'
cluster = require './config/cluster'
tables = require './config/tables'
jobQueue = require './services/service.jobQueue'
# just to make sure we can run the hirefire backup if necessary (in case the web process is down)
require './routes/route.hirefire'
shutdown = require './config/shutdown'
analyzeValue = require '../common/utils/util.analyzeValue'


queueName = process.argv[2]
quit = process.argv[3]?.toLowerCase() == 'quit'
tables.jobQueue.queueConfig()
.select('*')
.where(name: queueName)
.then (queues) ->
  if !queues || !queues.length
    logger.error "Can't find config for queue: #{queueName}"
    shutdown.exit(error: true)
  queue = queues[0]
  if !queue.active
    logger.error "Queue shouldn't be active: #{queueName}"
    shutdown.exit(error: true)

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
        logger.debug("All workers done; quitting master process.")
        shutdown.exit()
.catch (err) ->
  logger.error "Error processing job queue (#{queueName}):"
  logger.error "#{analyzeValue.getSimpleDetails(err)}"
  shutdown.exit(error: true)
