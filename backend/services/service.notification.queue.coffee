_ = require 'lodash'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
internals =  require './service.notification.queue.internals'

###
user_notification table intent is to be a notification history queue
for notifications to sent out and removed once processed.
###
class NotificationQueue extends ServiceCrud

  getAllWithConfigUser: (entity = {}, options = {}) =>

    @dbFn()
    .select(internals.explicitGetColumnsWithUserConfig)
      .innerJoin tables.user.notificationConfig.tableName
      , "#{tables.user.notificationConfig.tableName}.id"
      , "#{tables.user.notificationQueue.tableName}.config_notification_id"
      .innerJoin tables.auth.user.tableName
      , "#{tables.user.notificationConfig.tableName}.auth_user_id"
      , "#{tables.auth.user.tableName}.id"
      .where _.pick entity, internals.safeNotificationConfig


NotificationQueue.instance = new NotificationQueue(tables.user.notificationQueue)

module.exports = NotificationQueue
