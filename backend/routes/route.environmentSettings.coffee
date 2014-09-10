auth = require '../config/auth'
logger = require '../config/logger'
config = require '../config/config'
environmentSettingsService = require '../services/service.environmentSettings'


# I'm not sure that we'll actually need this route, but it was convenient for testing

module.exports = (app) ->
  app.get '/environment_settings/', auth.requireLogin(redirectOnFail: true), (req, res, next) ->
    logger.debug "getting environment settings for #{config.ENV}"
    environmentSettingsService.getSettings()
      .then (settings) ->
        logger.debug "got environment settings for #{config.ENV}"
        res.json(settings)
      .catch (err) ->
        message = "error getting environment settings for #{config.ENV}"
        logger.error message
        logger.error ''+(err.stack ? err)
        res.status(500).json(message)
