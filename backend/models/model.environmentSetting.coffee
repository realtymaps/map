dbs = require '../config/dbs'

# DEPRECATED: we will eliminate the EnvironmentSetting concept altogether at some point,
# and probably replace with some static config

module.exports = dbs.users.Model.extend
  tableName: 'management_environmentsetting'
