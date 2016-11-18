Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'
jobQueue = require '../services/service.jobQueue'
internals = require './task.geocode_fipsCodes.internals'


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
})
