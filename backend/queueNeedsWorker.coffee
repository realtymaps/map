hirefire = require('./services/service.hirefire')
logger = require('./config/logger').spawn('queueNeeds')
shutdown = require('./config/shutdown')
config = require './config/config'
cluster = require('cluster')
analyzeValue = require '../common/utils/util.analyzeValue'
errorHandlingUtils = require './utils/errors/util.error.partiallyHandledError'
cartodbConfig = require './config/cartodb/cartodb'


_intervalHandler = null


runOnce = () ->
  hirefire.updateQueueNeeds()
  .then (needs) ->
    if needs?
      logger.spawn('needs').debug('Current queue needs:')
      for queue in needs
        logger.spawn('needs').debug("    #{queue.name}: #{queue.quantity}")

repeat = (period=config.HIREFIRE.RUN_WINDOW) ->
  _intervalHandler = setInterval(runOnce, period)
  runOnce()
  return undefined

cancelRepeat = () ->
  clearInterval(_intervalHandler)

wake = () -> Promise.try () ->
  cartodbConfig()
  .then (cartoConfig) ->
    logger.spawn('wake').debug 'Cartodb config:'
    logger.spawn('wake').debug cartoConfig

    Promise.map cartoConfig.WAKE_URLS, (url) ->
      logger.spawn('wake').debug () -> "Posting Wake URL: #{url}"
      request({url, headers: 'Content-Type': 'application/json;charset=utf-8'})
    .then () ->
      logger.spawn('wake').debug 'All Wake Success!!'
    .catch (err) ->
      logger.error "Unexpected error performing cartoDb wake: #{analyzeValue.getSimpleDetails(err)}"


module.exports = {
  runOnce
  repeat
  cancelRepeat
}



if require.main == module  # run directly, not require()d

  if cluster.isMaster
    shutdown.setup()

    # first, spawn off a wake worker
    cluster.fork({WAKE_WORKER: true})

    # then do real queueNeeds stuff
    workerId = null
    workerForked = false
    intervalsWaited = 0
    cluster.on 'fork', (worker) ->
      logger.spawn('processes').debug "worker #{worker.id} forked"
      workerId = worker.id
    cluster.on 'exit', (worker) ->
      logger.spawn('processes').debug "worker #{worker.id} exited"
      workerId = null
      workerForked = false
      intervalsWaited = 0
    spawnWorker = () ->
      if !workerId?
        if workerForked
          logger.error('Worker forked, but no id registered!!!')
          shutdown.exit(error: true)
          return
        logger.spawn('processes').debug "attempting fork..."
        workerForked = true
        cluster.fork()
        return
      intervalsWaited++
      if intervalsWaited <= 2
        logger.spawn('processes').debug "silent wait..."
        return
      logger.warn "Waited #{intervalsWaited} intervals, worker has not finished"
      if intervalsWaited == 5
        logger.warn 'Attempting to terminate gracefully (SIGTERM)'
        cluster.workers[workerId]?.kill('SIGTERM')
      else if intervalsWaited == 6
        logger.warn 'YOU ARE TERMINATED! (SIGKILL)'
        cluster.workers[workerId]?.kill('SIGKILL')
      else if intervalsWaited >= 7
        logger.error 'COMMITTING SUICIDE'
        shutdown.exit(error: true)
    masterLoop = () ->
      spawnWorker()
      setInterval(spawnWorker, config.HIREFIRE.RUN_WINDOW)

    hirefire.getLastUpdateTimestamp()
    .then (timestamp) ->
      wait = timestamp + config.HIREFIRE.RUN_WINDOW - Date.now()
      if wait < 0
        wait = 0
      setTimeout(masterLoop, wait)
  else  # is worker
    shutdown.setup()

    if process.env.WAKE_WORKER
      setInterval(wake, config.CARTO_WAKE_INTERVAL)
      return

    runOnce()
    .then () ->
      shutdown.exit()
    .catch (err) ->
      logger.error "Unexpected error updating queue needs: #{analyzeValue.getSimpleDetails(err)}"
      shutdown.exit(error: true)
