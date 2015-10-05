_ = require 'lodash'
logger = require '../config/logger'
tables = require '../config/tables'

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
  'notes'
]

{crud, ThenableCrud, thenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'

for key, val of toInit
  module.exports[key] = crud(val)

permissionCols = [
  "#{tables.auth.m2m_user_permission.tableName}.id as id"
  'user_id'
  'permission_id'
  'content_type_id'
  'name'
  'codename'
]

groupsCols = [
  "#{tables.auth.m2m_user_group.tableName}.id as id"
  'user_id'
  'group_id'
  'name'
]

profileCols = [
  "#{tables.user.profile.tableName}.id as id"
  "#{tables.user.profile.tableName}.name as #{tables.user.profile.tableName}_name"
  "#{tables.user.project.tableName}.name as #{tables.user.project.tableName}_name"
  'filters', 'properties_selected', 'map_toggles', 'map_position', 'map_results',
  'parent_auth_user_id', 'auth_user_id as user_id'
]

class UserCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  permissions: thenableHasManyCrud(tables.auth.permission, permissionCols,
    module.exports.m2m_user_permission, 'permission_id', undefined, "#{tables.auth.m2m_user_group.tableName}.id")
    .init(false)

  groups: thenableHasManyCrud(tables.auth.group, groupsCols,
    module.exports.m2m_user_group, 'group_id', undefined, "#{tables.auth.m2m_user_group.tableName}.id").init(false)

  profiles: thenableHasManyCrud(tables.user.project, profileCols,
    module.exports.profile, undefined, undefined, "#{tables.user.profile.tableName}.id").init(false)


module.exports.user = new UserCrud(tables.auth.user)
