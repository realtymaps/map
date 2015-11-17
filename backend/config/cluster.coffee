# Include the cluster module
Promise = require 'bluebird'
cluster = require('cluster')
config = require './config'
logger = require './logger'

#http://stackoverflow.com/questions/19796102/exit-event-in-worker-process-when-killed-from-master-within-a-node-js-cluster
shutdownNow = (prefix, exitCode) ->
  logger.debug "#{prefix}: shutting down ..."
  setTimeout () ->
    logger.debug "#{prefix}: quitting"
    process.exit(exitCode)
  , 10000


catchUncaughtErrors = (prefix, err) ->
  logger.error "#{prefix}: Something very bad happened.  ", err.message
  logger.error err.stack || err
  # and now GTFO, because you are in unpredictable state
  shutdownNow(prefix, 1)


module.exports = (clusterName, options={}, workerCb) ->
  workerCount = 1 #options.workerCount ? config.PROC_COUNT
  allowQuit = !!options.allowQuit
  quitWorkerCount = 0
  if workerCount == 1
    #dont add fork overhead if only 1 process is needed
    return workerCb()

  getWorkerPrefix = (worker) ->
    "Worker Process <#{clusterName}-#{worker.id}>"


  # catch all uncaught exceptions, no matter what process it happens on

  if cluster.isMaster
    masterPrefix = "Master Process <#{clusterName}>"
    logger.debug "#{masterPrefix}: starting"
    process.on 'uncaughtException', catchUncaughtErrors.bind(null, masterPrefix)
    logger.debug "#{masterPrefix}: forking #{workerCount} workers..."
    for i in [1..workerCount]
      logger.debug "#{masterPrefix}: ... worker #{i} forking ... "
      cluster.fork()

    cluster.on 'exit', (worker) ->
      if allowQuit
        quitWorkerCount++
        logger.info "#{getWorkerPrefix(worker)}: quit"
        if quitWorkerCount == workerCount
          logger.info "#{masterPrefix}: #{quitWorkerCount} workers have quit, now quitting from master"
          process.exit(0)
      else
        logger.error "#{getWorkerPrefix(worker)}: exited"
        logger.debug "#{masterPrefix}: forking new worker"
        cluster.fork()

    return

  logger.debug "#{getWorkerPrefix(cluster.worker)}: starting"
  process.on 'uncaughtException', catchUncaughtErrors.bind(null, getWorkerPrefix(cluster.worker))
  for signal in ['SIGINT', 'SIGTERM']
    process.on signal, shutdownNow.bind(null, getWorkerPrefix(cluster.worker), 0)

  workerCb()
