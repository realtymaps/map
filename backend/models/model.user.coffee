dbs = require '../config/dbs'
Group = require './model.group'
Permission = require './model.permission'

module.exports = dbs.users.Model.extend
  tableName: "auth_user"
  groups: () ->
    @belongsToMany(Group, "auth_user_groups", "user_id", "group_id")
  permissions: () ->
    @belongsToMany(Permission, "auth_user_user_permissions", "user_id", "permission_id")
