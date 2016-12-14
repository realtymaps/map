# Include the cluster module
cluster = require('cluster')
config = require './config'
logger = require('./logger').spawn('cluster')
shutdown = require './shutdown'


module.exports = (clusterName, options={}, workerCb) ->
  workerCount = options.workerCount ? config.PROC_COUNT
  allowQuit = !!options.allowQuit
  quitWorkerCount = 0
  if workerCount == 1
    #dont add fork overhead if only 1 process is needed
    shutdown.setup()
    return workerCb()

  getWorkerPrefix = (worker) ->
    "Worker Process <#{clusterName}-#{worker.id}>"

  if cluster.isMaster
    masterPrefix = "Master Process <#{clusterName}>"
    logger.debug "#{masterPrefix}: starting"
    shutdown.setup(true)

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
          shutdown.exit()
      else
        logger.error "#{getWorkerPrefix(worker)}: exited, forking replacement"
        logger.debug "#{masterPrefix}: forking new worker"
        cluster.fork()

    return

  logger.debug "#{getWorkerPrefix(cluster.worker)}: starting"
  shutdown.setup()

  workerCb()
