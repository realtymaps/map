dbs = require '../config/dbs'

module.exports = dbs.properties.Model.extend
  tableName: 'temp_mls_data2'
