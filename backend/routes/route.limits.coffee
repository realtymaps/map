logger = require '../config/logger'
pack = require '../../package.json'
routes = require '../config/routes'

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
  logger.debug "WTF"
  logger.info "WTF"
  app.get routes.limits, (req, res) ->
    console.info "limits hit %j", req
    logger.info "limits"
    res.send(limits)
