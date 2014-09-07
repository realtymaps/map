logger = require '../config/logger'

# I'm not sure that we'll actually need this route, but it was convenient for testing

module.exports = (app) ->
  environmentSettingsService = require('../services/service.environmentSettings')(app)

  app.get '/environment_settings/', (req, res) ->
    logger.info "get environment settings"
    environmentSettingsService.getSettings (err, settings) ->
      res.send(settings)
