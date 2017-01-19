_ = require 'lodash'
tables = require '../config/tables'
notificationConfigInternals = require './service.notification.config.internals'

getColumns = [
  'id'
  'config_notification_id'
  'options'
  'rm_inserted_time'
  'last_attempt_time'
  'attempts'
  'error'
  'status'
]

explicitGetColumns = getColumns.map (col) ->
  "#{tables.user.notificationQueue.tableName}.#{col}"

explicitGetColumnsWithUserConfig = _.flatten explicitGetColumns.concat [
  _.without(notificationConfigInternals.allColumns,
    "#{tables.user.notificationConfig.tableName}.id"
    "#{tables.user.notificationFrequencies.tableName}.id"
    "#{tables.user.notificationMethods.tableName}.id"
  )
]

module.exports = {
  getColumns
  explicitGetColumns
  explicitGetColumnsWithUserConfig
}
