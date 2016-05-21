_ = require 'lodash'
tables = require '../config/tables'
notificationConfigInternals = require './service.notification.config.internals'

getColumns = [
  'id'
  'config_notifcation_id'
  'options'
  'rm_inserted_time'
  'last_attempt_time'
  'attempts'
  'error'
]

explicitGetColumns = "#{tables.user.notification}.#{col}" for col in getColumns

explicitGetColumnsWithUserConfig = explicitGetColumns.concat(
  _.without notificationConfigInternals, ['id']
)

module.exports = {
  getColumns
  explicitGetColumns
  explicitGetColumnsWithUserConfig
}
