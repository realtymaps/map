_ = require 'lodash'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
internals =  require './service.notification.config.internals'

###
The config_notification table and service intent is for handling how users
would like to receive notifications and how often.
###
class NotifcationConfigService extends ServiceCrud

  getAllWithUser: (entity = {}, options = {}) ->
    # not worrying about error handling convienence of wrapQuery
    # because this complicates things where you need to worry about reverts etc..
    options.returnKnex = true
    {knex} = @getAll(entity, options)

    knex.select("auth_user_id", "method", "email", "cell_phone")
    .innerJoin(
      tables.auth.user.tableName,
      "#{tables.user.notificationConfig.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id"
    )
    .where _.pick entity, internals.allColumns


NotifcationConfigService.instance = new NotifcationConfigService tables.user.notificationConfig


module.exports = NotifcationConfigService
