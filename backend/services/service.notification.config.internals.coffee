tables = require '../config/tables'

getColumns = [
  'id'
  'auth_user_id'
  'type'
  'method'
  'frequency'
  'bubble_direction'
  'max_attempts'
]

explicitGetColumns = "#{tables.config.notification}.#{col}" for col in getColumns

module.exports = {
  getColumns
  explicitGetColumns
}
