_ = require 'lodash'
tables = require '../config/tables'
config = require '../config/config'
logger = require('../config/logger').spawn('service:notification:queue')
internals =  require './service.notification.queue.internals'
NotifcationBaseService = require './service.notification.base'
sqlHelpers = require '../utils/util.sql.helpers'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'


###
user_notification table intent is to be a notification history queue
for notifications to sent out and removed once processed.
###
class NotificationQueue extends NotifcationBaseService

  getAllWithConfigUser: (entity = {}, options = {}) =>
    entity = @mapEntity(entity)

    @dbFn()
    .select(internals.explicitGetColumnsWithUserConfig)
    .innerJoin(tables.user.notificationConfig.tableName, "#{tables.user.notificationConfig.tableName}.id",
      "#{tables.user.notificationQueue.tableName}.config_notification_id")
    .innerJoin(tables.user.notificationMethods.tableName, "#{tables.user.notificationMethods.tableName}.id",
      "#{tables.user.notificationConfig.tableName}.method_id")
    .innerJoin(tables.user.notificationFrequencies.tableName, "#{tables.user.notificationFrequencies.tableName}.id",
      "#{tables.user.notificationConfig.tableName}.frequency_id")
    .innerJoin(tables.auth.user.tableName, "#{tables.user.notificationConfig.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id")
    .where(entity)


NotificationQueue.instance = new NotificationQueue(tables.user.notificationQueue)

NotificationQueue.cleanup = {
  getDisabled: (type) ->
    l = logger.spawn("getTimedOut")

    l.debugQuery(
      tables.user.notificationQueue()
      .select(
        "#{tables.user.notificationQueue.tableName}.id",
        "config_notification_id"
        tables.user.notificationQueue.raw("options->>'type' as options_type")
        tables.user.notificationQueue.raw("options->>'frequency' as options_frequency"))
      .join("#{tables.user.notificationConfig.tableName} as config", "config.id", "config_notification_id")
      .join("#{tables.user.notificationFrequencies.tableName} as freq", "freq.id", "config.frequency_id")
      .whereRaw("?? != ?", ["freq.code_name", "options->>'frequency'"])
      # .where("freq.code_name", "=", "off")
    )

  handleDisabled: (disables) ->
    l = logger.spawn("handleDisabled")
    l.debugQuery(
      sqlHelpers.whereIn(tables.user.notificationQueue(),'id', _.map(disables,'id'))
      .delete()
    )


  getTimedOut: (type) ->
    l = logger.spawn("getTimedOut")
    l.debugQuery(
      tables.user.notificationQueue()
      .where () ->
        @where status: 'pending'
        @orWhere status: null
      .whereNotNull 'last_attempt_time'
      .whereRaw "options->>'type' = ?", [type]
      .whereRaw "now_utc() - last_attempt_time  > interval '#{config.NOTIFICATIONS.DELIVERY_THRESH_MIN} minutes'"
      .where 'attempts', '<', config.NOTIFICATIONS.MAX_ATTEMPTS
    )

  getMaxxedOut: (transaction) ->
    l = logger.spawn("getMaxxedOut")

    l.debugQuery(
      tables.user.notificationQueue({transaction})
      .whereNotNull 'last_attempt_time'
      .whereRaw "now_utc() - last_attempt_time  > interval '#{config.NOTIFICATIONS.DELIVERY_THRESH_MIN} minutes'"
      .where 'attempts', '>=', config.NOTIFICATIONS.MAX_ATTEMPTS
    )

  handleMaxxed: (transaction) ->
    l = logger.spawn("handleMaxxed")
    badRows = []

    maxedOutRows = _.filter maxedOutRows, (r) ->
      exists = !!r.id
      if !exists
        badRows.push r
      exists

    if !maxedOutRows.length
      l.debug -> "@@@@ MAXXED OUT ROWS: GTFO @@@@"
      return

    l.debug -> "@@@@ MAXXED OUT ROWS LENGTH: #{maxedOutRows.length}"

    if badRows.length
      l.debug -> "@@@@ MAXXED OUT ROWS LENGTH: #{maxedOutRows.length}"
      l.debug -> "@@@@ BAD ROWS LENGTH: #{badRows.length}"
      l.debug -> badRows

    #MOVE to Expired
    tables.user.notificationExpired({transaction})
    .insert(maxedOutRows.map (r) -> _.omit r, 'id')
    .then () ->
      query = null
      clauseArg = _.pluck(maxedOutRows, 'id')

      logger.debug -> "@@@@ MAXXED OUT ROWS LENGTH (POST INSERT): #{maxedOutRows.length}"

      logIfError = (logQuery = false) ->
        l.debug -> query.toString() if logQuery
        l.debug -> "@@@@ maxedOutRows @@@@"
        l.debug -> maxedOutRows
        l.debug -> "@@@@ clauseArg @@@@"
        l.debug -> clauseArg

      #Clean out Expired from queue
      query = sqlHelpers.whereIn(tables.user.notificationQueue({transaction}), 'id', clauseArg).delete()

      .catch errorHandlingUtils.isKnexUndefined, (error) ->
        logIfError()
        throw new errorHandlingUtils.PartiallyHandledError(error, "isKnexUndefined: failed to clean maxedOutRows")
      .catch errorHandlingUtils.isUnhandled, (error) ->
        logIfError(true)
        throw new errorHandlingUtils.PartiallyHandledError(error, "isUnhandled: failed to clean maxedOutRows")


}

module.exports = NotificationQueue
