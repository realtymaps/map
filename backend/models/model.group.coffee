dbs = require '../config/dbs'
Permission = require './model.permission'
User = require './model.user'

# DEPRECATED: we will stop using this (and bookshelf.js) in favor of /config/tables.coffee and knex

module.exports = dbs.users.Model.extend
  tableName: "auth_group",
  users: () ->
    @belongsToMany(User, "auth_user_groups", "group_id", "user_id")
  permissions: () ->
    @belongsToMany(Permission, "auth_group_permissions", "group_id", "permission_id")
