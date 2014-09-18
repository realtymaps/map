dbs = require '../config/dbs'
SessionSecurity = require './model.sessionSecurity'

module.exports = dbs.users.Model.extend
  tableName: "session"
  sessionSecurity: () ->
    @hasOne(SessionSecurity)
