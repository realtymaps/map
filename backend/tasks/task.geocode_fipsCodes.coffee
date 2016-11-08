Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'
dataLoadHelpers = require './util.dataLoadHelpers'
jobQueue = require '../services/service.jobQueue'
logger = require('../config/logger').spawn('task:geocode:fipsCodes')
internals = require './task.geocode_fipsCodes.internals'


ready = () ->
  logger.debug -> 'ready'
  dataLoadHelpers
  .checkReadyForRefresh({task_name: 'geocode_fipsCodes'},
    {targetHour: 2, targetDay: 'Saturday', runIfNever: true})
  .then (result) ->
    logger.debug ->'checkReadyForRefresh'
    logger.debug -> result
    result


loadRawData = (subtask) ->
  Promise.join(jobQueue.queueSubsequentSubtask({
    subtask
    laterSubtaskName: 'normalize'
  }),
  jobQueue.queueSubsequentSubtask({
    subtask
    laterSubtaskName: 'finalize'
  }))
  .then () ->
    internals.loadRawData(subtask)


module.exports = new TaskImplementation('geocode_fipsCodes', {
  loadRawData
  normalize: internals.normalize
  finalize: internals.finalize
}, ready)
