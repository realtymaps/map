dbs = require '../config/dbs'

module.exports = dbs.properties.Model.extend
  tableName: 'county_data1_copy'
