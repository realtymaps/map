dbs = require '../config/dbs'

module.exports = dbs.properties.Model.extend
  tableName: "mv_property_details"
