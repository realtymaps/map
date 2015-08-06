Promise = require 'bluebird'
logger = require '../config/logger'
jobQueue = require '../utils/util.jobQueue'
ExpressResponse = require '../utils/util.expressResponse'

info = (req, res, next) -> Promise.try () ->
  jobQueue.doMaintenance()
  .then () ->
    jobQueue.updateTaskCounts()
  .then () ->
    jobQueue.queueReadyTasks()
  .then () ->
    jobQueue.getQueueNeeds()
  .then (needs) ->
    next new ExpressResponse(needs)
  .catch (err) ->
    logger.error "unexpected error during hirefire info check: #{err}"
    next(err)

module.exports =
  info: info
