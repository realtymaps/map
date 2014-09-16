logger = require '../config/logger'
pack = require '../../package.json'
routes = require '../../common/config/routes'

#a place for system restraints
limits = require '../config/frontend'

module.exports = (app) ->
  logger.infoRoute 'limits', routes.limits
  app.get routes.limits, (req, res) ->
    logger.log 'debug', "limits hit %j", limits, {}
    res.send(limits)
