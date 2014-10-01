auth = require '../utils/util.auth'
logger = require '../config/logger'
config = require '../config/config'
environmentSettingsService = require '../services/service.environmentSettings'
routes = require '../../common/config/routes'

module.exports = (app) ->
  logger.infoRoute 'environmentSettings', routes.environmentSettings
  app.get routes.environmentSettings
  , auth.requireLogin(redirectOnFail: true)
  , (req, res, next) ->
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
