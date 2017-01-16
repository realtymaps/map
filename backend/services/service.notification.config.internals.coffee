tables = require '../config/tables'

basicColumns = [
  'id'
  'frequency_id'
  'method_id'
  'auth_user_id'
  'type'
]

getColumns = [
  'auth_user_id'
  'type'
  "#{tables.user.notificationMethods.tableName}.code_name as method"
  "#{tables.user.notificationFrequencies.tableName}.code_name as frequency"
]

userColumns = [
  'first_name'
  'last_name'
  'email'
  'cell_phone'
  'work_phone'
]

allColumns = getColumns.concat "#{tables.user.notificationConfig.tableName}.id", userColumns, [
  "#{tables.user.notificationFrequencies.tableName}.code_name"
  "#{tables.user.notificationMethods.tableName}.code_name"
]

explicitGetColumns = getColumns.concat('id').map (col) ->
  "#{tables.user.notificationConfig.tableName}.#{col}"


explicitUserColumns = userColumns.concat('id').map (col) ->
  "#{tables.auth.user.tableName}.#{col}"

module.exports = {
  basicColumns
  allColumns
  userColumns
  getColumns
  explicitGetColumns
  explicitUserColumns
}
