tables = require '../config/tables'

getColumns = [
  'id'
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

allColumns = getColumns.concat userColumns

explicitGetColumns = "#{tables.user.notificationConfig}.#{col}" for col in getColumns

module.exports = {
  allColumns
  userColumns
  getColumns
  explicitGetColumns
}
