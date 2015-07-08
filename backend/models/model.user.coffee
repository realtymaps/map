dbs = require '../config/dbs'
Group = require './model.group'
Permission = require './model.permission'
Profile = require './model.profile'
Project = require './model.project'
{userData} = require '../config/tables'

# DEPRECATED: we will stop using this (and bookshelf.js) in favor of /config/tables.coffee and knex

module.exports = dbs.users.Model.extend
  tableName: userData.user.tableName
  groups: () ->
    @belongsToMany Group, userData.auth_user_groups.tableName
      , "user_id", "group_id"
  permissions: () ->
    @belongsToMany Permission, userData.auth_user_user_permissions.tableName
      , "user_id", "permission_id"
  profiles: () ->
    @belongsTo Profile, Profile.tableName
      , "auth_user_id", "id"
  # projects: () ->
  #   @hasOne(Project).through(Profile)
