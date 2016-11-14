_ = require 'lodash'
Promise = require 'bluebird'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
config = require '../config/config'
dbs = require '../config/dbs'
logger = require('../config/logger.coffee').spawn('task:events:notifications:internals')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
notifyQueueSvc = require('../services/service.notification.queue').instance
notificationsSvc = require '../services/service.notifications'
utilEvents = require './util.events.coffee'
sqlHelpers = require '../utils/util.sql.helpers'


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

  queryEntity =
    status: null

  for name in loadSubtaskOptions
    if subtask?.data?[name]?
      queryEntity["#{tables.user.notificationConfig.tableName}.#{name}"] = subtask.data[name]

  _deleteNotifications()
  .then () ->

    notifyQueueSvc.getAllWithConfigUser queryEntity
    .where 'attempts', '<', config.NOTIFICATIONS.MAX_ATTEMPTS
    .then (rows) ->
      logger.debug "@@@@@@@@@@@@@@@@@@@@@@"
      logger.debug "loadNotifications to sendNotifications row.length: #{rows.length}"
      logger.debug "@@@@@@@@@@@@@@@@@@@@@@"

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

    Use webhook for emailVero, sms but not on email (node mailer).

    ###
    row.options.notification_id = row.id

    dbs.get("main").transaction (transaction) ->
      q = tables.user.notificationQueue({transaction})
      .where id: row.id
      .update {
        status: 'pending'
        last_attempt_time: tables.user.notificationQueue().raw 'now_utc()'
        attempts: row.attempts + 1
      }
      logger.debug "@@@@@@ PENDING UPDATE @@@@@@"
      logger.debug q.toString()
      q.then () ->
        notificationsSvc.sendNotificationNow {row, options: row.options, transaction}
        .then () ->
          logger.debug '!!!!!!!!!!!!!! notification send success !!!!!!!!!!!!!!'

          if !config.NOTIFICATIONS.USE_WEBHOOKS
            logger.debug '@@@@ NO WEBHOOKS DELETING @@@@'
            tables.user.notificationQueue({transaction})
            .where id: row.id
            .delete()

        .catch (err) ->
          throw err

    .catch (err) ->
      details = analyzeValue.getFullDetails(err)
      logger.error "notification error: #{details}"

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
  _deleteNotifications()
  .then () ->
  Promise.map utilEvents.notificationTypes, (type) ->
    query = tables.user.notificationQueue()
    .where () ->
      @where status: 'pending'
      @orWhere status: null
    .whereNotNull 'last_attempt_time'
    .whereRaw "options->>'type' = ?", [type]
    .whereRaw "now_utc() - last_attempt_time  > interval '#{config.NOTIFICATIONS.DELIVERY_THRESH_MIN} minutes'"
    .where 'attempts', '<', config.NOTIFICATIONS.MAX_ATTEMPTS


    logger.debug "@@@@@@@@@@@@@@@@@@@@@@"
    logger.debug query.toString()
    logger.debug "@@@@@@@@@@@@@@@@@@@@@@"

    handle = utilEvents.cleanupHandlers[type] || utilEvents.cleanupHandlers.default
    handle(query)
  .then () ->
    dbs.transaction (transaction) ->
      #get maxed out rows and move them out
      maxQuery = tables.user.notificationQueue({transaction})
      .whereNotNull 'last_attempt_time'
      .whereRaw "now_utc() - last_attempt_time  > interval '#{config.NOTIFICATIONS.DELIVERY_THRESH_MIN} minutes'"
      .where 'attempts', '>=', config.NOTIFICATIONS.MAX_ATTEMPTS

      logger.debug "@@@@@@@@@@@@@@@@@@@@@@"
      logger.debug maxQuery.toString()
      logger.debug "@@@@@@@@@@@@@@@@@@@@@@"


      maxQuery.then (maxedOutRows) ->
        badRows = []

        maxedOutRows = _.filter maxedOutRows, (r) ->
          exists = !!r.id
          if !exists
            badRows.push r
          exists

        if !maxedOutRows.length
          logger.debug -> "@@@@ MAXXED OUT ROWS: GTFO @@@@"
          return

        logger.debug -> "@@@@ MAXXED OUT ROWS LENGTH: #{maxedOutRows.length}"

        if badRows.length
          logger.debug -> "@@@@ MAXXED OUT ROWS LENGTH: #{maxedOutRows.length}"
          logger.debug -> "@@@@ BAD ROWS LENGTH: #{badRows.length}"
          logger.debug -> badRows
          # what should I do with the badRows if I have no id to update them with?

        tables.user.notificationExpired({transaction})
        .insert(maxedOutRows.map (r) -> _.omit r, 'id')
        .then () ->
          query = null
          clauseArg = _.pluck(maxedOutRows, 'id')

          logger.debug -> "@@@@ MAXXED OUT ROWS LENGTH (POST INSERT): #{maxedOutRows.length}"

          logIfError = (logQuery = false) ->
            logger.debug -> query.toString() if logQuery
            logger.debug "@@@@ maxedOutRows @@@@"
            logger.debug -> maxedOutRows
            logger.debug "@@@@ clauseArg @@@@"
            logger.debug -> clauseArg

          query = sqlHelpers.whereIn(tables.user.notificationQueue({transaction}), 'id', clauseArg)
          .delete()

          .catch errorHandlingUtils.isKnexUndefined, (error) ->
            logIfError()
            throw new errorHandlingUtils.PartiallyHandledError(error, "isKnexUndefined: failed to clean maxedOutRows")
          .catch errorHandlingUtils.isUnhandled, (error) ->
            logIfError(true)
            throw new errorHandlingUtils.PartiallyHandledError(error, "isUnhandled: failed to clean maxedOutRows")


module.exports = {
  loadNotifications
  sendNotifications
  cleanupNotifications
}
