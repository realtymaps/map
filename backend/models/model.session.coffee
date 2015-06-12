dbs = require '../config/dbs'
SessionSecurity = require './model.sessionSecurity'

# DEPRECATED: we will stop using this (and bookshelf.js) in favor of /config/tables.coffee and knex

module.exports = dbs.users.Model.extend
  tableName: "session"
  sessionSecurity: () ->
    @hasOne(SessionSecurity)
