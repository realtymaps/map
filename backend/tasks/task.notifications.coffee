TaskImplementation = require './util.taskImplementation'
logger = require('../config/logger.coffee').spawn('task:notifications')
internals = require './task.notifications.internals'
dataLoadHelpers = require './util.dataLoadHelpers'

daily = (subtask) ->
  dataLoadHelpers.checkReadyForRefresh(subtask, targetHour: 5)  # target 5am every day
  .then (doRefresh) ->
    if !doRefresh
      return

    logger.debug 'Attempting Daily notifications'

    internals.loadNotifications subtask, 'daily'

onDemand = (subtask) ->
  internals.loadNotifications subtask, 'onDemand'


module.exports = new TaskImplementation 'notifications', {
  daily
  onDemand
  sendNotifications: internals.sendNotifications
}
