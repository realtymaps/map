TaskImplementation = require './util.taskImplementation'
logger = require('../config/logger.coffee').spawn('task:notifications')
internalsNotifications = require './task.events.notifications.internals'
internalsDequeue = require './task.events.dequeue.internals'
dataLoadHelpers = require './util.dataLoadHelpers'

dailyEvents = (subtask) ->
  dataLoadHelpers.checkReadyForRefresh(subtask, targetHour: 4)  # target 4am every day
  .then (doRefresh) ->
    if !doRefresh
      return

    internalsDequeue.loadEvents {
      subtask
      frequency: 'daily'
      doDequeue: true
    }

onDemandEvents = (subtask) ->
  internalsDequeue.loadEvents {
    subtask
    frequency: 'onDemand'
    doDequeue: false
  }

# TODO: remove as this is not needed, only onDemandNotifications -> notifications
# is needed as notifications are queued up as fast as necessary (onDemand and daily).
# Therefore, we can just send them out as fast as possible.
dailyNotifications = (subtask) ->
  logger.debug 'Attempting Daily notifications'
  internalsNotifications.loadNotifications {
    subtask
    frequency: 'daily'
  }

onDemandNotifications = (subtask) ->
  internalsNotifications.loadNotifications {
    subtask
    frequency: 'onDemand'
  }


module.exports = new TaskImplementation 'events', {
  dailyEvents
  onDemandEvents
  compactEvents: internalsDequeue.compactEvents
  processEvent: internalsDequeue.processEvent
  doneEvents: internalsDequeue.doneEvents
  dailyNotifications
  onDemandNotifications
  sendNotifications: internalsNotifications.sendNotifications
}
