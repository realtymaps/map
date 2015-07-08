dbs = require '../config/dbs'
Session = require './model.session'

# DEPRECATED: we will stop using this (and bookshelf.js) in favor of /config/tables.coffee and knex

module.exports = dbs.users.Model.extend
  tableName: "session_security"
  session: () ->
    @belongsTo(Session)
  hasTimestamps: true
,
  knex: () -> dbs.users.knex('session_security')
