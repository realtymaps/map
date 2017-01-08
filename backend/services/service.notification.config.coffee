_ = require 'lodash'
tables = require '../config/tables'
internals =  require './service.notification.config.internals'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("service:notification")
# coffeelint: enable=check_scope
sqlHelpers = require '../utils/util.sql.helpers'
NotifcationBaseService = require './service.notification.base'


###
The config_notification table and service intent is for handling how users
would like to receive notifications and how often.
###
class NotifcationConfigService extends NotifcationBaseService

  getAll: (entity = {}, options = {}) ->
    entity = @mapEntity(entity)
    options.query = @dbFn().select(internals.basicColumns)
    super(entity, options)

  getAllWithUser: (entity = {}, options = {}) ->
    l = logger.spawn('getAllWithUser')
    l.debug -> 'original Entity'
    l.debug -> entity
    entity = @mapEntity(entity)
    l.debug -> 'mapped Entity'
    l.debug -> entity

    q = @dbFn(options)
    .select(internals.allColumns)
    .innerJoin(
      tables.auth.user.tableName,
      "#{tables.auth.user.tableName}.id",
      "#{tables.user.notificationConfig.tableName}.auth_user_id")
    .innerJoin(
      tables.user.notificationMethods.tableName,
      "#{tables.user.notificationMethods.tableName}.id",
      "#{tables.user.notificationConfig.tableName}.method_id")
    .innerJoin(
      tables.user.notificationFrequencies.tableName,
      "#{tables.user.notificationFrequencies.tableName}.id",
      "#{tables.user.notificationConfig.tableName}.frequency_id")

    if _.keys(entity).length
      if options.whereAndWhereIn
        return sqlHelpers.whereAndWhereIn(q, entity)

      q.where _.pick entity, internals.allColumns
    q

NotifcationConfigService.instance = new NotifcationConfigService(tables.user.notificationConfig)


module.exports = NotifcationConfigService
