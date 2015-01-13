dbs = require '../config/dbs'

module.exports = dbs.properties.Model.extend
  tableName: "v_property_details"
