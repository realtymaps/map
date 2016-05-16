_ = require 'lodash'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
tables = require '../config/tables'
internals =  require './service.notification.config.internals'


class NotifcationConfigService extends ServiceCrud

  getAllWithUser: (entity = {}, options = {}) ->
    # not worrying about error handling convienence of wrapQuery
    # because this complicates things where you need to worry about reverts etc..
    options.returnKnex = true
    {knex} = @getAll(entity, options)

    knex.select("auth_user_id", "method", "email", "cell_phone")
    .innerJoin(
      tables.auth.user.tableName,
      "#{tables.config.notification.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id"
    )
    .where _.pick entity, internals.getColumns


NotifcationConfigService.instance = new NotifcationConfigService tables.config.notification

module.exports = NotifcationConfigService
