Promise = require 'bluebird'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
dbs = require '../config/dbs'
logger = require('../config/logger.coffee').spawn('task:events:notifications:internals')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
notifyQueueSvc = require('../services/service.notification.queue').instance
notificationsSvc = require '../services/service.notifications'


NUM_ROWS_TO_PAGINATE = 100
# DELAY_MILLISECONDS = 50

###
  subtask will have the necessary info to figure out
  what notifications to send out
###
loadNotifications = ({subtask, frequency}) -> Promise.try () ->
  if !frequency
    throw new HardFail 'frequency must be defined'

  if !subtask.data?
    subtask.data = {}

  subtask.data.frequency ?= frequency

  logger.debug "Starting #{frequency} Notifications."
  numRowsToPageSendNotifications = subtask?.data?.numRowsToPageSendNotifications || NUM_ROWS_TO_PAGINATE

  loadSubtaskOptions = [
    'frequency'
    'method'
  ]

  queryEntity = {}

  for name in loadSubtaskOptions
    if subtask?.data?[name]?
      queryEntity["#{tables.user.notificationConfig.tableName}.#{name}"] = subtask.data[name]

  #return a list of user_notification.id to be paged
  notifyQueueSvc.getAllWithConfigUser queryEntity
  .select "#{tables.user.notificationQueue.tableName}.id"
  .then (rows) ->
    logger.debug "@@@@@@@@@@@@@@@@@@@@@@"
    logger.debug "loadNotifications to sendNotifications row.length: #{rows.length}"
    logger.debug "@@@@@@@@@@@@@@@@@@@@@@"

    jobQueue.queueSubsequentPaginatedSubtask {
      subtask
      totalOrList: rows
      maxPage: numRowsToPageSendNotifications
      laterSubtaskName: "sendNotifications"
    }

sendNotifications = (subtask) ->
  rows = subtask?.data?.values
  if !rows?.length
    return
  logger.debug "@@@@@@@@@ sendNotifications rows @@@@@@@@@@@@@"
  logger.debug rows
  logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

  Promise.all Promise.map rows, (row) ->
    ###TODO: we need mark column as having a webhook
     Send notification out mark as sent/pending, and send out specific user_notificaiton_id to know which to remove/update

     handle webhook later to handlesuccess and removal
     where:
      - success removes user_notification_queue item where pending and specific id
      - fail, remove pending column so it is retried by job task

    ###
    dbs.get("main").transaction (transaction) ->
      notificationsSvc.sendNotificationNow {row, options: row.options, transaction}
      .then () ->
        logger.debug '!!!!!!!!!!!!!! notification send success !!!!!!!!!!!!!!'
        # logger.debug row.id
        q = tables.user.notificationQueue({transaction})
        .where id: row.id
        .delete()
        logger.debug q.toString()
        q
      .catch (err) ->
        throw err

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
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to sendNotifications')
  .catch (error) ->
    throw new HardFail(analyzeValue.getSimpleMessage(error))

module.exports = {
  loadNotifications
  sendNotifications
}
