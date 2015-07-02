_ = require 'lodash'
{userData} = require('../config/tables')
toInit = _.pick userData, [
  'auth_group'
  'auth_user_groups'
  'auth_permission'
  'auth_group_permissions'
  'auth_user_profile'
  'project'
  'auth_user_user_permissions'
]

{crud,Crud} = require '../utils/crud/util.crud.service.helpers'

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
#HMMM this is where Bookshelf would kill this, should we use Bookshelf to handle standard
#crud with hasMany?

class UserCrud extends Crud
  permissions: () ->
    getAll: (user_id) ->
      userData.auth_user_user_permissions()
      .select(permissionCols...)
      .innerJoin(userData.auth_permission.tableName,
        userData.auth_permission.tableName+ ".id",
        userData.auth_user_user_permissions.tableName + '.permission_id')
      .where(user_id:user_id)


  groups: () ->
    getAll: (user_id) ->
      userData.auth_user_groups()
      .select(groupsCols...)
      .innerJoin(userData.auth_group.tableName,
        userData.auth_group.tableName+ ".id",
        userData.auth_user_groups.tableName + '.group_id')
      .where(user_id:user_id)

  profiles: () ->
    getAll: (user_id) ->
      userData.auth_user_profile().select().where(auth_user_id:user_id)

module.exports.user = new UserCrud(userData.user)
