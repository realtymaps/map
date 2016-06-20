TaskImplementation = require './util.taskImplementation'
internals = require './task.eventsDequeue.internals'
dataLoadHelpers = require './util.dataLoadHelpers'


daily = (subtask) ->
  dataLoadHelpers.checkReadyForRefresh(subtask, targetHour: 4)  # target 4am every day
  .then (doRefresh) ->
    if !doRefresh
      return

    internals.loadEvents {
      subtask
      frequency: 'daily'
      doDequeue: true
    }

onDemand = (subtask) ->
  internals.loadEvents {
    subtask
    frequency: 'onDemand'
    doDequeue: false
  }

module.exports = new TaskImplementation 'eventsDequeue', {
  daily
  onDemand
  compactEvents: internals.compactEvents
  processEvent: internals.processEvent
}
