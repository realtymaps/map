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

{crud,Crud, hasManyCrud} = require '../utils/crud/util.crud.service.helpers'

for key, val of toInit
  module.exports[key] = crud(val)

permissionCols = [
  "user_id"
  "permission_id"
  "#{userData.auth_user_user_permissions.tableName}.id as #{userData.auth_user_user_permissions.tableName}_id"
  "content_type_id"
  "name"
  "codename"
]

groupsCols = [
  "user_id"
  "group_id"
  "name"
]

profileCols = [
  "#{userData.auth_user_profile.tableName}.id as #{userData.auth_user_profile.tableName}_id"
  "#{userData.auth_user_profile.tableName}.name as #{userData.auth_user_profile.tableName}_name"
  "#{userData.project.tableName}.name as #{userData.project.tableName}_name"
  'filters', 'properties_selected', 'map_toggles', 'map_position', 'map_results',
  'parent_auth_user_id', 'auth_user_id as user_id'
]

class UserCrud extends Crud
  constructor: () ->
    super(arguments...)

    @profilesQuery = (user_id) -> userData.auth_user_profile().select().where(auth_user_id:user_id)

  permissions: hasManyCrud(userData.auth_permission, permissionCols,
    module.exports.auth_user_user_permissions, "permission_id", undefined, "auth_user_user_permissions.id")

  groups: hasManyCrud(userData.auth_group, groupsCols,
    module.exports.auth_user_groups, "group_id", undefined, "group_id")

  profiles: hasManyCrud(userData.project, profileCols, module.exports.auth_user_profile, "project_id")


module.exports.user = new UserCrud(userData.user)
