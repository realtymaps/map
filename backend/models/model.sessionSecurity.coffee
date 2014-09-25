dbs = require '../config/dbs'
Session = require './model.session'

module.exports = dbs.users.Model.extend {
  tableName: "session_security"
  session: () ->
    @belongsTo(Session)
  hasTimestamps: true
}, {
  knex: dbs.users.knex('session_security')
}
