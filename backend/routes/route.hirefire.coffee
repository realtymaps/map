Promise = require 'bluebird'
logger = require '../config/logger'
jobQueue = require '../utils/util.jobQueue'
ExpressResponse = require '../utils/util.expressResponse'
keystore = require '../services/service.keystore'


RUN_WINDOW = 120000
SKIP_WINDOW = 10000
HIREFIRE_RUN_TIMESTAMP = 'hirefire run timestamp'


info = (req, res, next) -> Promise.try () ->
  clearTimeout(_timeout)
  # continue to slightly stagger checks, just in case the initial stagger was unlucky
  _timeout = setTimeout(_checkIfRun, RUN_WINDOW + Math.random()*SKIP_WINDOW)
  
  now = Date.now()
  keystore.setUserDbValue(HIREFIRE_RUN_TIMESTAMP, now)
  .then (priorTimestamp=now) ->
    # if it turns out we ran not that long ago (race condition), don't bother if this isn't a real hirefire hit 
    if now - priorTimestamp < SKIP_WINDOW && req == null
      return
    jobQueue.doMaintenance()
    .then () ->
      jobQueue.updateTaskCounts()
    .then () ->
      jobQueue.queueReadyTasks()
    .then () ->
      jobQueue.getQueueNeeds()
    .then (needs) ->
      if next
        next new ExpressResponse(needs)
    .catch (err) ->
      logger.error "unexpected error during hirefire info check: #{err.stack||err}"
      if next
        next(err)


# stagger initial checks to avoid simultaneous checks from startup
_timeout = setTimeout(_checkIfRun, RUN_WINDOW + Math.random()*RUN_WINDOW)

_checkIfRun = () ->
  keystore.getUserDbValue(HIREFIRE_RUN_TIMESTAMP, defaultValue: 0)
  .then (timestamp) ->
    if Date.now() - timestamp >= RUN_WINDOW
      logger.warn "Hirefire hasn't run since #{new Date(timestamp)}, manually executing"
      info()
    return undefined

    
module.exports =
  info: info
