Promise = require 'bluebird'
_ = require 'lodash'
logger = require('../config/logger').spawn('service:notifications')
analyzeValue = require '../../common/utils/util.analyzeValue'
errorHelpers = require '../utils/errors/util.error.partiallyHandledError'
internals = require './service.notifications.internals'
internalsNotificationConfig = require './service.notification.config.internals'
notificationConfigService =  require('./service.notifcation.config').instance
notificationUserService =  require('./service.notifcation.user').instance
internalsNotificationUser = require './service.notification.user.internals'
###
  Intended to be the workflow service which combines business logic of
  config_notification with user_notification. This is mainly intended for queing
  and actually sending notifications.
###


sendNotificationNow = ({configRows, options}) ->
  emails = []
  emailIds = []
  smsPromises = []

  # loop to build emails as well as send sms
  # if notification lists grow large, we may need to refine this loop
  for datum in configRows
    do (datum) ->
      if datum.email and datum.method == 'email'
        emails.push datum.email
        emailIds.push datum.id

      # sms currently required to send one by one; If we implement
      # an async or bulk method, we can handle it similar to email
      if datum.cell_phone and datum.method == 'sms'
        smsPromises.push internals.sendSmsNowPromise {datum, options}

  Promise.join(
    internals.sendBasicEmailNowPromise({emailIds, emails, options}),
    Promise.all(smsPromises)
  )
  .catch errorHelpers.isUnhandled, (err) ->
    throw new errorHelpers.PartiallyHandledError(err, 'Unhandled immediate notification error')
  .catch (err) ->
    logger.error "notification error: #{analyzeValue.getSimpleDetails(err)}"

###
  Adds a row to user_notification.
  First gets the config attributes and then merges the options to fill out
  other columns.
###
sendNotificationEventually = ({configRows, options}) ->
  Promise.all Promise.map configRows, (row) ->
    entity =
      config_notification_id: row.id

    _.extend entity, _.pick options, internalsNotificationUser.getColumns
    notificationUserService.create entity

notificationHandles =
  email: sendNotificationNow
  sms: sendNotificationNow
  emailVero: sendNotificationEventually

notification = ({type, method}) ->
  (options) ->
    safeFields = _.pick options, internalsNotificationConfig.getColumns
    entity = _.extend safeFields, {type, method}

    logger.debug entity

    notificationConfigService
    .getAllWithUser(entity)
    .then (configRows) ->
      notificationHandles[method] {configRows, options}

module.exports =
  notification: notification
