_ = require 'lodash'
logger = require('../config/logger').spawn('services:user')
tables = require '../config/tables'
{Crud, ThenableCrud, ThenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'
{joinColumns} = require '../utils/util.sql.columns'


module.exports.accountUseTypes = new Crud(tables.lookup.accountUseTypes)

module.exports.group = new Crud(tables.auth.group)
module.exports.permission = new Crud(tables.auth.permission)
module.exports.m2m_group_permission = new Crud(tables.auth.m2m_group_permission)
module.exports.m2m_user_permission = new Crud(tables.auth.m2m_user_permission)
module.exports.m2m_user_group = new Crud(tables.auth.m2m_user_group)

module.exports.profile = new Crud(tables.user.profile)
module.exports.project = new Crud(tables.user.project)
module.exports.company = new Crud(tables.user.company)
module.exports.drawnShapes = new Crud(tables.user.drawnShapes)
module.exports.notes = new Crud(tables.user.notes)


class UserCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  init: () =>
    # taking care of inits here fore internal svcs so they can be overridden
    # logger.debug 'INIT UserCrud Service'
    @permissions = new ThenableHasManyCrud(tables.auth.permission, joinColumns.permission,
      module.exports.m2m_user_permission, 'permission_id', undefined,
      "#{tables.auth.m2m_user_group.tableName}.id").init(arguments...)

    @groups = new ThenableHasManyCrud(tables.auth.group, joinColumns.groups,
      module.exports.m2m_user_group, 'group_id', undefined,
      "#{tables.auth.m2m_user_group.tableName}.id").init(arguments...)

    @clients = new ThenableHasManyCrud(tables.auth.user, joinColumns.client,
      module.exports.profile, undefined, undefined,
      "#{tables.user.profile.tableName}.id").init(arguments...)
    super(arguments...)


module.exports.user = new UserCrud(tables.auth.user).init(false)
