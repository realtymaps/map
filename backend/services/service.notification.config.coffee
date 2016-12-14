_ = require 'lodash'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
internals =  require './service.notification.config.internals'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("service:notification")
# coffeelint: enable=check_scope
clone = require 'clone'

###
The config_notification table and service intent is for handling how users
would like to receive notifications and how often.
###
class NotifcationConfigService extends ServiceCrud

  getAllWithUser: (entity = {}, options = {}) ->
    entity = clone entity
    if entity.id?
      entity["#{tables.user.notificationConfig.tableName}.id"] = entity.id
      delete entity.id

    @dbFn(options)
    .select(internals.allColumns)
    .innerJoin(
      tables.auth.user.tableName,
      "#{tables.user.notificationConfig.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id")
    .where _.pick entity, internals.allColumns

NotifcationConfigService.instance = new NotifcationConfigService(tables.user.notificationConfig)


module.exports = NotifcationConfigService
