_ = require("lodash")
Promise = require "bluebird"
memoize = require "memoizee"

logger = require '../config/logger'
config = require '../config/config'
EnvironmentSetting = require("../models/model.environmentSetting")


# coerce values (which are all strings in the db) to the appropriate types here
hashifySettings = (hash, setting) ->
  try
    if setting.setting_type is "string"
      value = setting.setting_value
    else if setting.setting_type is "integer"
      value = parseInt(setting.setting_value)
    else if setting.setting_type is "decimal"
      value = parseFloat(setting.setting_value)
    hash[setting.setting_name] = value;
  catch error
    logger.warn "error casting setting '#{setting.setting_name}' to type '#{setting.setting_type}', had value '#{setting.setting_value}': "+error.toString()
  return hash


getSettings = () ->
  # we want to get the all_environments values first...
  defaultSettings = EnvironmentSetting.where(environment_name: "all_environments").fetchAll()
    .then (settings) -> return settings.toJSON()
    .reduce(hashifySettings, {})
  # ... then override them with the specific environment values
  specificSettings = EnvironmentSetting.where(environment_name: config.ENV).fetchAll()
    .then (settings) -> return settings.toJSON()
    .reduce(hashifySettings, {})
  allSettings = Promise.join defaultSettings, specificSettings, (defaultSettings, specificSettings) ->
    return _.merge(defaultSettings, specificSettings)
  allSettings
    .then (settings) ->
      logger.debug "all environment settings loaded (#{config.ENV}):"
      logger.debug JSON.stringify(settings, null, 2)
    .catch (err) ->
      logger.error "error loading environment settings (#{config.ENV})"
  return allSettings
# wrap function in a caching memoizer
getSettings = memoize(getSettings, { maxAge: config.DB_CACHE_TIMES.SLOW_REFRESH, prefetch: .1 })

module.exports = {
  getSettings: getSettings
}
