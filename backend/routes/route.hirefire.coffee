Promise = require 'bluebird'
logger = require '../config/logger'
jobQueue = require '../utils/util.jobQueue'
ExpressResponse = require '../utils/util.expressResponse'
keystore = require '../services/service.keystore'


RUN_WINDOW = 120000
DELAY_VARIATION = 10000
HIREFIRE_RUN_TIMESTAMP = 'hirefire run timestamp'


_checkIfRun = () ->
  keystore.getUserDbValue(HIREFIRE_RUN_TIMESTAMP, defaultValue: 0)
  .then (timestamp) ->
    if Date.now() - timestamp >= RUN_WINDOW
      logger.warn "Hirefire hasn't run since #{new Date(timestamp)}, manually executing"
      _priorTimestamp = timestamp
      module.exports.info()
    return undefined

# stagger initial checks to avoid simultaneous checks from startup
initial_delay = RUN_WINDOW + Math.floor(Math.random()*DELAY_VARIATION)
_timeout = setTimeout(_checkIfRun, initial_delay)
_priorTimestamp = null


info = (req, res, next) -> Promise.try () ->
  clearTimeout(_timeout)
  # continue to slightly stagger checks, just in case the initial stagger was unlucky
  _timeout = setTimeout(_checkIfRun, RUN_WINDOW + Math.floor(Math.random()*DELAY_VARIATION))
  
  now = Date.now()
  keystore.setUserDbValue(HIREFIRE_RUN_TIMESTAMP, now)
  .then (currentTimestamp=now) ->
    # if it turns out something else has started running since we determined we should run (race condition),
    # don't bother running if this isn't a real hirefire hit (let the other one handle it) 
    if _priorTimestamp? && currentTimestamp != _priorTimestamp && req == null
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


module.exports =
  info: info
