_ = require 'lodash'
logger = require('../config/logger').spawn('service:notifications')
# tables = require '../config/tables'
# analyzeValue = require '../../common/utils/util.analyzeValue'
errorHelpers = require '../utils/errors/util.error.partiallyHandledError'
internals = require './service.notifications.internals'
notificationConfigService = require('./service.notification.config').instance
internalsNotificationConfig = require './service.notification.config.internals'
sqlHelpers = require '../utils/util.sql.helpers'
###
  Intended to be the workflow service which combines business logic of
  config_notification with user_notification. This is mainly intended for queing
  and actually sending notifications.
###
sendNotificationNow = ({row, options}) ->
  logger.debug "@@@@ sendNotificationNow prior getAllWithUser@@@@"
  logger.debug row
  logger.debug options

  handle = internals.sendHandles[row.method] || internals.sendHandles.default

  handle(row, options)
  .catch errorHelpers.isUnhandled, (err) ->
    throw new errorHelpers.PartiallyHandledError(err, 'Unhandled immediate notification error')

###
  Public: enqueues notifications to user_notifcation_queue.

  The intent is to match up users to their user_notification_config.
  Once they are matched up we can create user_notification_queue for each user.

  This is used more for subscriptions and distributions.

  - `opts`:   The opts as {object}.
    - `to`    see internals.distribute.getUsers (where to go)
    - `id`    see internals.distribute.getUsers(id of the auth_user initiating the notification)
    - `type`  The type of notification as {string or Array<string>} (pinned, favorite).
    - `project_id`  {int}
    - `payload` The options column for a specific notificaiton. {object}.
        This is a json blob to put into a user_notification to be processed by whatever
        notification handler.

  Returns a {Promise}.
###
notifyByUser = ({opts, payload}) ->
  logger.debug "@@@@@@ notifyByUser opts @@@@@@"
  logger.debug opts
  logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@"

  internals.distribute.getFromUser(opts.id)
  .then (rows) ->
    if !rows.length
      logger.warn "User not found aborting notification creation. User id: #{opts.id}"
      return
    [fromUser] = rows

    payload.from = fromUser

    internals.distribute.getUsers(to: opts.to, id: opts.id, project_id: opts.project_id)
    .then (users) ->
      entity = auth_user_id: _.pluck(users, 'id')
      _.extend entity, _.pick opts, ['type', 'method']

      logger.debug "@@@@ notifyByUser: entity @@@@"
      logger.debug entity
      logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

      query = sqlHelpers.whereAndWhereIn notificationConfigService.getAllWithUser(), entity

      logger.debug "@@@@ notifyByUser: internals.enqueue @@@@"
      internals.enqueue {
        configRowsQuery: query
        options: payload
        verify: opts.verify
        verbose: opts.verbose
        from: 'notifyByUser'
        project_id: opts.project_id
        type: opts.type
      }

###
  Grab specific notification configs by type and or method

 - `type`  The type of notification as {string or Array<string>} (pinned, favorite).
 - `method` The method of notification as {string}.

  Returns a function to actually execute the enqueueing of a notification.

###
notifyFlat = ({type, method, verify, verbose}) ->
  ###
   - `payload`      The user_notification options payload {object}.
   - `queryOptions` The query entity to narrow the query {object}.

    Returns Promise.
  ###
  ({payload, queryOptions}) ->
    safeFields = _.pick queryOptions, internalsNotificationConfig.getColumns
    entity = _.extend safeFields, {type, method}

    logger.debug entity

    configRowsQuery = notificationConfigService.getAllWithUser(entity)

    logger.debug "@@@@ notifyFlat: internals.enqueue @@@@"
    internals.enqueue {
      configRowsQuery
      options: payload
      verify: verify
      verbose: verbose
      from: 'notifyFlat'
    }


module.exports = {
  sendNotificationNow
  notifyByUser
  notifyFlat
}
