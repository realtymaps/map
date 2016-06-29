tables = require '../config/tables'

getColumns = [
  'auth_user_id'
  'type'
  'method'
  'frequency'
  'max_attempts'
]

userColumns = [
  'first_name'
  'last_name'
  'email'
  'cell_phone'
  'work_phone'
]

allColumns = getColumns.concat "#{tables.user.notificationConfig.tableName}.id", userColumns

explicitGetColumns = getColumns.concat('id').map (col) ->
  "#{tables.user.notificationConfig.tableName}.#{col}"


explicitUserColumns = userColumns.concat('id').map (col) ->
  "#{tables.auth.user.tableName}.#{col}"

module.exports = {
  allColumns
  userColumns
  getColumns
  explicitGetColumns
  explicitUserColumns
}
