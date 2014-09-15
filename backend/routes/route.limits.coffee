logger = require '../config/logger'
pack = require '../../package.json'
routes = require '../../common/config/routes'

#a place for system restraints
limits =
  map:
    options:
      streetViewControl: false
      panControl: false
      maxZoom: 20
      minZoom: 3
  doLog: true

module.exports = (app) ->
  logger.infoRoute 'limits', routes.limits
  app.get routes.limits, (req, res) ->
    logger.log 'debug', "limits hit %j", req, {}
    res.send(limits)
