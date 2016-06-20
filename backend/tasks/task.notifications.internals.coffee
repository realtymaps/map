Promise = require 'bluebird'
_ = require 'lodash'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
logger = require('../config/logger.coffee').spawn('task:notifications:internals')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
notifyQueueSvc = require '../services/service.notification.queue'
notificationsSvc = require '../services/service.notifications'
sqlHelpers = require '../utils/util.sql.helpers'

NUM_ROWS_TO_PAGINATE = 100
# DELAY_MILLISECONDS = 50

###
  subtask will have the necessary info to figure out
  what notifications to send out
###
loadNotifications = (subtask, frequency) -> Promise.try () ->
  if !frequency
    throw new HardFail 'frequency must be defined'

  subtask.data?.frequency = frequency
  logger.debug "Starting #{frequency} Notifications."


  numRowsToPageSendNotifications = subtask?.data?.numRowsToPageSendNotifications || NUM_ROWS_TO_PAGINATE

  loadSubtaskOptions = [
    'frequency'
    'method'
  ]

  queryEntity = {}

  for name in loadSubtaskOptions
    if subtask?.data[name]?
      queryEntity["#{tables.user.notificationConfig.tableName}.#{name}"] = subtask.data[name]

  #return a list of user_notification.id to be paged
  notifyQueueSvc.getAllWithConfigUser queryEntity
  .select "#{tables.user.notificationQueue.tableName}.id"
  .then (ids) ->
    ids  = _.pluck(ids, "#{tables.user.notificationQueue.tableName}.id")
    jobQueue.queueSubsequentPaginatedSubtask {
      subtask
      totalOrList: ids
      maxPage: numRowsToPageSendNotifications
      laterSubtaskName: "sendNotifications"
    }

sendNotifications = (subtask) ->
  sqlHelpers.whereAndWhereIn(notifyQueueSvc.getAllWithConfigUser(),
    "#{tables.user.notificationQueue.tableName}.id": subtask.data.values)
  .whereNull('error')
  .then (rows) ->
    Promise.all Promise.map rows, (row) ->
      ###TODO: we need mark column as having a webhook
       Send notification out mark as sent/pending, and send out specific user_notificaiton_id to know which to remove/update

       handle webhook later to handlesuccess and removal
       where:
        - success removes user_notification_queue item where pending and specific id
        - fail, remove pending column so it is retried by job task

      ###
      notificationsSvc.sendNotificationsNow row, row.options
      .then () ->
        logger.debug 'notification send success'

        tables.user.notificationQueue()
        .where id: row.id
        .delete()

      .catch (err) ->
        details = analyzeValue.getSimpleDetails(err)
        logger.error "notification error: #{details}"

        if row.attempts >= row.maxAttempts
          #mark with error and no longer try it
          tables.user.notificationQueue()
          .update error: details
        else
          tables.user.notificationQueue()
          .update {
            options: row.options
            config_notification_id: row.config_notification_id
            error: details
            attempts: row.attempts++
          }
          .where id: row.id

  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to load parcels data for update')
  .catch (error) ->
    throw new SoftFail(analyzeValue.getSimpleMessage(error))

module.exports = {
  loadNotifications
  sendNotifications
}
