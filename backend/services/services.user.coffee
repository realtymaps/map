_ = require 'lodash'
logger = require '../config/logger'
{userData} = require '../config/tables'
userModel = require '../models/model.user'
toInit = _.pick userData, [
  'auth_group'
  'auth_user_groups'
  'auth_permission'
  'auth_group_permissions'
  'auth_user_profile'
  'project'
  'auth_user_user_permissions'
]

{crud,ThenableCrud, thenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'

for key, val of toInit
  module.exports[key] = crud(val)

permissionCols = [
  "#{userData.auth_user_user_permissions.tableName}.id as id"
  "user_id"
  "permission_id"
  "content_type_id"
  "name"
  "codename"
]

groupsCols = [
  "#{userData.auth_user_groups.tableName}.id as id"
  "user_id"
  "group_id"
  "name"
]

profileCols = [
  "#{userData.auth_user_profile.tableName}.id as id"
  "#{userData.auth_user_profile.tableName}.name as #{userData.auth_user_profile.tableName}_name"
  "#{userData.project.tableName}.name as #{userData.project.tableName}_name"
  'filters', 'properties_selected', 'map_toggles', 'map_position', 'map_results',
  'parent_auth_user_id', 'auth_user_id as user_id'
]

class UserCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  permissions: thenableHasManyCrud(userData.auth_permission, permissionCols,
    module.exports.auth_user_user_permissions, "permission_id", undefined, "auth_user_user_permissions.id")
    .init(false)

  groups: thenableHasManyCrud(userData.auth_group, groupsCols,
    module.exports.auth_user_groups, "group_id", undefined, "group_id").init(false)

  profiles: thenableHasManyCrud(userData.project, profileCols,
    module.exports.auth_user_profile, undefined, undefined, 'auth_user_profile.id').init(false)


module.exports.user = new UserCrud(userData.user)
