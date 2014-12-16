dbs = require '../config/dbs'

module.exports = dbs.users.Model.extend
  tableName: "user_state"
