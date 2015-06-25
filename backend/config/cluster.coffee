# Include the cluster module
Promise = require 'bluebird'
cluster = Promise.promisifyAll require('cluster')
config = require './config'
logger = require './logger'

#http://stackoverflow.com/questions/19796102/exit-event-in-worker-process-when-killed-from-master-within-a-node-js-cluster
shutdownNow = ->
  logger.debug('shutting down ...')
  setTimeout () ->
    logger.debug 'quitting'
    process.exit(0)
  , 10000

module.exports = (workerCb) ->
  if cluster.isMaster
    headerMsg = "Master Cluster "
    logger.debug headerMsg + " Starting"

    # Count the machine's CPUs
    cpuCount = config.PROC_COUNT

    logger.debug headerMsg + "forking #{cpuCount} processes"
    #Create a worker for each CPU
    [1..cpuCount].forEach ->
      cluster.forkAsync()

    cluster.onAsync('exit').then (worker) ->
      logger.error("Worker #{worker.id} died :(")
      logger.debug headerMsg + "forking new worker"
      cluster.fork()

    return
    
  logger.debug "Worker Cluster ##{cluster.worker.id} Starting"
  process.on 'SIGINT', shutdownNow
  process.on 'SIGTERM', shutdownNow
  workerCb(cluster)
