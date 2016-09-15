logger = require('./config/logger').spawn('masterWorker')
shutdown = require('./config/shutdown')
cluster = require('cluster')
analyzeValue = require '../common/utils/util.analyzeValue'
loaders = require './utils/util.loaders'

workers = loaders.loadSubmodules(__dirname, './workers', /^(\w+)\.coffee$/)


if require.main == module  # run directly, not require()d

  if cluster.isMaster

    # do setup

    shutdown.setup()

    spawnQueue = []
    forkingWorkerKey = undefined

    forkNext = () ->
      if spawnQueue.length
        forkingWorkerKey = spawnQueue.shift()
        cluster.fork(WORKER_KEY: forkingWorkerKey)
      else
        forkingWorkerKey = null

    cluster.on 'fork', (worker) ->
      worker.WORKER_KEY = forkingWorkerKey
      workers[forkingWorkerKey].id = worker.id
      logger.spawn(worker.WORKER_KEY).debug "worker #{worker.id} forked (WORKER_KEY: #{forkingWorkerKey})"
      forkNext()

    cluster.on 'exit', (worker) ->
      logger.spawn(worker.WORKER_KEY).debug "worker #{worker.id} exited (WORKER_KEY: #{worker.WORKER_KEY})"
      workers[worker.WORKER_KEY].id = null
      workers[worker.WORKER_KEY].intervalsWaited = 0

    checkWorkerStatus = (workerKey) ->
      workerConfig = workers[workerKey]
      if !workerConfig.id?
        logger.spawn(workerKey).debug "attempting fork..."
        spawnQueue.push(workerKey)
        if !forkingWorkerKey
          forkNext()
        return
      workerConfig.intervalsWaited++
      if workerConfig.intervalsWaited <= workerConfig.silentWait
        logger.spawn(workerKey).debug "silent wait..."
        return
      logger.warn "Waited #{workerConfig.intervalsWaited} intervals, worker has not finished"
      if workerConfig.intervalsWaited >= workerConfig.crash
        logger.error 'COMMITTING SUICIDE'
        shutdown.exit(error: true)
      else if workerConfig.intervalsWaited >= workerConfig.kill
        logger.warn 'YOU ARE TERMINATED! (SIGKILL)'
        cluster.workers[workerConfig.id]?.kill('SIGKILL')
      else if workerConfig.intervalsWaited >= workerConfig.gracefulTermination
        logger.warn 'Attempting to terminate gracefully (SIGTERM)'
        cluster.workers[workerConfig.id]?.kill('SIGTERM')

    # kick things off
    delay = 0
    for workerKey of workers
      doStuff = (workerKey) ->
        workerConfig = workers[workerKey]
        workerConfig.intervalsWaited = 0
        checkWorkerStatus(workerKey)
        setInterval(checkWorkerStatus, workerConfig.interval, workerKey)
      setTimeout(doStuff, delay, workerKey)
      delay += 10000  # stagger startups by 10s


  else  # is worker
    shutdown.setup()

    workerConfig = workers[process.env.WORKER_KEY]
    workerConfig.worker()
    .then () ->
      shutdown.exit()
    .catch (err) ->
      logger.error "Unexpected error running #{process.env.WORKER_KEY} worker: #{analyzeValue.getSimpleDetails(err)}"
      shutdown.exit(error: true)
