Promise = require 'bluebird'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
config = require '../config/config'
dbs = require '../config/dbs'
logger = require('../config/logger.coffee').spawn('task:events:notifications:internals')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{HardFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
notifyQueueSvc = require('../services/service.notification.queue').instance
notifyQueueCleanup = require('../services/service.notification.queue').cleanup
notificationsSvc = require '../services/service.notifications'
utilEvents = require './util.events.coffee'



NUM_ROWS_TO_PAGINATE = 100

_deleteNotifications = () ->
  tables.user.notificationQueue()
  .where status: 'delivered'
  .delete()
###
  subtask will have the necessary info to figure out
  what notifications to send out
###
loadNotifications = ({subtask, frequency}) -> Promise.try () ->
  l = logger.spawn("loadNotifications")

  if !frequency
    throw new HardFail 'frequency must be defined'

  if !subtask.data?
    subtask.data = {}

  subtask.data.frequency ?= frequency

  logger.debug -> "Starting #{frequency} Notifications."
  numRowsToPageSendNotifications = subtask?.data?.numRowsToPageSendNotifications || NUM_ROWS_TO_PAGINATE

  queryEntity =
    status: null

  if subtask?.data?.frequency?
    queryEntity.frequency = subtask.data.frequency
  if subtask?.data?.method?
    queryEntity.method = subtask.data.method

  _deleteNotifications()
  .then () ->

    l.debugQuery(notifyQueueSvc.getAllWithConfigUser queryEntity
    .where 'attempts', '<', config.NOTIFICATIONS.MAX_ATTEMPTS)
    .then (rows) ->
      l.debug -> "@@@@@@@@@@@@@@@@@@@@@@"
      l.debug -> " to sendNotifications row.length: #{rows.length}"
      l.debug ->"@@@@@@@@@@@@@@@@@@@@@@"

      Promise.all [
        jobQueue.queueSubsequentPaginatedSubtask {
          subtask
          totalOrList: rows
          maxPage: numRowsToPageSendNotifications
          laterSubtaskName: "sendNotifications"
        }
        jobQueue.queueSubsequentSubtask {
          subtask
          laterSubtaskName: 'cleanupNotifications'
        }
      ]
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, "failed to load #{frequency} notifications")
  .catch (error) ->
    throw new HardFail(analyzeValue.getSimpleMessage(error))

sendNotifications = (subtask) ->
  l = logger.spawn("sendNotifications")
  rows = subtask?.data?.values
  if !rows?.length
    return
  l.debug -> "@@@@@@@@@ rows @@@@@@@@@@@@@"
  l.debug -> rows
  l.debug -> "@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

  Promise.all Promise.map rows, (row) ->
    # Deliveries should normally be confirmed in webhooks to mark the user_notification_queue status as delivered or not
    # see route.webhooks
    row.options.notification_id = row.id

    dbs.get("main").transaction (transaction) ->
      q = tables.user.notificationQueue({transaction})
      .where id: row.id
      .update {
        status: 'pending'
        last_attempt_time: tables.user.notificationQueue().raw 'now_utc()'
        attempts: row.attempts + 1
      }
      l.debug -> "@@@@@@ PENDING UPDATE @@@@@@"
      l.debug -> q.toString()
      q.then () ->
        notificationsSvc.sendNotificationNow {row, options: row.options, transaction}
        .then () ->
          l.debug -> '!!!!!!!!!!!!!! notification send success !!!!!!!!!!!!!!'
          l.debug -> "config.NOTIFICATIONS.USE_WEBHOOKS: #{config.NOTIFICATIONS.USE_WEBHOOKS}"
          if !config.NOTIFICATIONS.USE_WEBHOOKS
            l.debug -> '@@@@ NO WEBHOOKS DELETING @@@@'
            l.debugQuery( tables.user.notificationQueue({transaction}).where(id: row.id).delete())

        .catch (err) ->
          throw err

    .catch (err) ->
      details = analyzeValue.getFullDetails(err)
      l.error "notification error: #{details}"

      tables.user.notificationQueue()
      .update {
        options: row.options
        config_notification_id: row.config_notification_id
        error: details
        status: null
      }
      .where id: row.id

  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to sendNotifications')
  .catch (error) ->
    throw new HardFail(analyzeValue.getSimpleMessage(error))

cleanupNotifications = (subtask) ->
  l = logger.spawn("cleanupNotifications")

  _deleteNotifications()
  .then () ->
  Promise.map utilEvents.notificationTypes, (type) ->
    handle = utilEvents.cleanupHandlers[type] || utilEvents.cleanupHandlers.default
    l.debug -> "handle: #{handle}"

    handle(notifyQueueCleanup.getTimedOut(type))#usually deletes timedout here if handle is propertySaved
    .then () ->
      notifyQueueCleanup.getDisabled(type)
      .then (deletes) ->
        notifyQueueCleanup.handleDisabled(deletes)
  .then () ->
    dbs.transaction (transaction) ->
      notifyQueueCleanup.getMaxxedOut(transaction)
      .then (maxedOutRows) ->
        notifyQueueCleanup.handleMaxxed(transaction)


module.exports = {
  loadNotifications
  sendNotifications
  cleanupNotifications
}
