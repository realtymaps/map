logger = require '../config/logger'
_ = require("lodash")

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


module.exports = (app) ->
  EnvironmentSetting = require("../models/environmentSetting")(app)
  
  return {
    getSettings: (callback) ->
      # we want to get the all_environments values first...
      EnvironmentSetting.where(environment_name: "all_environments").fetchAll()
        .then (allEnvironmentSettings) ->
          settings = {}
          _.reduce(allEnvironmentSettings.toJSON(), hashifySettings, settings)
          # ... then override them with the specific environment values
          EnvironmentSetting.where(environment_name: process.env.NODE_ENV).fetchAll()
            .then (specificEnvironmentSettings) ->
              _.reduce(specificEnvironmentSettings.toJSON(), hashifySettings, settings)
              process.nextTick(callback.bind(null, null, settings))
            .catch((err) -> process.nextTick(callback.bind(null, err)))
        .catch((err) -> process.nextTick(callback.bind(null, err)))
  }
