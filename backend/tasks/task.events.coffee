Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'
logger = require('../config/logger').spawn('task:events')
internalsNotifications = require './task.events.notifications.internals'
internalsDequeue = require './task.events.dequeue.internals'
dataLoadHelpers = require './util.dataLoadHelpers'
tables = require '../config/tables'


subtasks = {
  compactEvents: internalsDequeue.compactEvents
  processEvent: internalsDequeue.processEvent
  doneEvents: internalsDequeue.doneEvents
  sendNotifications: internalsNotifications.sendNotifications
  cleanupNotifications: internalsNotifications.cleanupNotifications
}

promisedTask = tables.user.notificationFrequencies('code_name', 'target_hour', 'name')
.where('code_name', '!=', 'off')
.then (rows) ->
  logger.debug -> "setting up events"
  logger.debug -> rows

  Promise.each rows, ({code_name, target_hour, name}) ->
    #All Event Handlers
    subtasks["#{code_name}Events"] = (subtask) ->
      refreshPromise = Promise.resolve(true)
      if target_hour?
        logger.debug -> "using target hour: dataLoadHelpers.checkReadyForRefresh"
        refreshPromise = dataLoadHelpers.checkReadyForRefresh(subtask, targetHour: 4)  # target 4am every day

      refreshPromise.then (doRefresh) ->
        if !doRefresh
          return

        internalsDequeue.loadEvents {
          subtask
          frequency: code_name
          doDequeue: !!target_hour
        }

    #All Notification handlers
    subtasks["#{code_name}Notifications"] = (subtask) ->
      logger.debug -> "Attempting #{name} notifications"
      internalsNotifications.loadNotifications {
        subtask
        frequency: code_name
      }
  .then () ->
    subtasks
.then () ->
  logger.debug -> "subtasks should be ready"
  logger.debug -> subtasks
  new TaskImplementation 'events', subtasks


module.exports = promisedTask #because getTaskCode is promised based already, this should be fine
