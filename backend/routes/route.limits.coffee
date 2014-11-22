logger = require '../config/logger'
pack = require '../../package.json'
backendRoutes = require '../../common/config/routes.backend.coffee'

#a place for system restraints
limits = require '../config/frontend'

module.exports = (app) ->
  logger.infoRoute 'limits', backendRoutes.limits
  app.get backendRoutes.limits, (req, res) ->
    logger.log 'debug', "limits hit %j", limits, {}
    res.send(limits)
