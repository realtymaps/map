dbs = require '../config/dbs'
{userData} = require '../config/tables'
Project = require './model.project'
# DEPRECATED: we will stop using this (and bookshelf.js) in favor of /config/tables.coffee and knex

module.exports = dbs.users.Model.extend
  tableName: userData.auth_user_profile.tableName
  project: () ->
    @hasOne Project
