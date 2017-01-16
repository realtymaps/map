tables = require '../config/tables'
internals =  require './service.notification.queue.internals'
NotifcationBaseService = require './service.notification.base'


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

module.exports = NotificationQueue
