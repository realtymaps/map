Promise = require 'bluebird'
_ = require 'lodash'
logger = require('../config/logger').spawn('service:notifications')
analyzeValue = require '../../common/utils/util.analyzeValue'
errorHelpers = require '../utils/errors/util.error.partiallyHandledError'
internals = require './service.notifications.internals'
internalsNotificationConfig = require './service.notification.config.internals'
notificationConfigService =  require('./service.notifcation.config').instance
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


notificationHandles =
  immediate: sendNotificationNow

notification = ({type, frequency}) ->
  (options) ->
    safeFields = _.pick options, internalsNotificationConfig.getColumns
    entity = _.extend safeFields, {type, frequency}

    logger.debug entity

    notificationConfigService
    .getAllWithUser(entity)
    .then (configRows) ->
      notificationHandles[frequency] {configRows, options}

module.exports =
  notification: notification
