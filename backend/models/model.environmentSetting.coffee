dbs = require '../config/dbs'

module.exports = dbs.users.Model.extend
  tableName: "management_environmentsetting"
