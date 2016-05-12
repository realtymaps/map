_ = require 'lodash'
logger = require('../config/logger').spawn('service::user')
tables = require '../config/tables'
{crud, ThenableCrud, thenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'
{joinColumns} = require '../utils/util.sql.columns'

toInit = {}
_.extend toInit, _.pick tables.lookup, [
  'usStates'
  'accountUseTypes'
]
_.extend toInit, _.pick tables.auth, [
  'group'
  'permission'
  'm2m_group_permission'
  'm2m_user_permission'
  'm2m_user_group'
]
_.extend toInit, _.pick tables.user, [
  'profile'
  'project'
  'company'
  'accountImages'
  'drawnShapes'
  'notes'
]

for key, val of toInit
  module.exports[key] = crud(val)

class UserCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  init: () =>
    # taking care of inits here fore internal svcs so they can be overriden
    # logger.debug 'INIT UserCrud Service'
    @permissions = thenableHasManyCrud(tables.auth.permission, joinColumns.permission,
      module.exports.m2m_user_permission, 'permission_id', undefined,
      "#{tables.auth.m2m_user_group.tableName}.id").init(arguments...)

    @groups = thenableHasManyCrud(tables.auth.group, joinColumns.groups,
      module.exports.m2m_user_group, 'group_id', undefined,
      "#{tables.auth.m2m_user_group.tableName}.id").init(arguments...)

    @profiles = thenableHasManyCrud(tables.user.project, joinColumns.profile,
      module.exports.profile, "#{tables.user.profile.tableName}.project_id",
      undefined, "#{tables.user.profile.tableName}.id").init(arguments...)

    @clients = thenableHasManyCrud(tables.auth.user, joinColumns.client,
      module.exports.profile, undefined, undefined,
      "#{tables.user.profile.tableName}.id").init(arguments...)
    super(arguments...)

module.exports.user = new UserCrud(tables.auth.user).init(false)
