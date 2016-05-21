_ = require 'lodash'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
internals =  require './service.notification.user.internals'


class NotifcationUserService extends ServiceCrud

  getAllWithConfigUser: (entity = {}, options = {}) ->
    # not worrying about error handling convienence of wrapQuery
    # because this complicates things where you need to worry about reverts etc..
    options.returnKnex = true
    {knex} = @getAll(entity, options)

    knex.select(internals.explicitGetColumnsWithUserConfig)
      .innerJoin tables.config.notification.tableName
      , "#{tables.config.notification.tableName}.id"
      , "#{tables.user.notifcation.tableName}.config_notifcation_id"
      .innerJoin tables.auth.user.tableName
      , "#{tables.config.notification.tableName}.auth_user_id"
      , "#{tables.auth.user.tableName}.id"
      .where _.pick entity, internals.safeNotificationConfig


NotifcationUserService.instance = NotifcationUserService tables.user.notification

module.exports = NotifcationUserService
