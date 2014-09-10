dbs = require '../config/dbs'
Group = require './model.group'
User = require './model.user'

module.exports = dbs.users.Model.extend
  tableName: "auth_permission",
  users: () ->
    @belongsToMany(User, "auth_user_user_permissions", "permission_id", "user_id")
  groups: () ->
    @belongsToMany(Group, "auth_group_permissions", "permission_id", "group_id")
