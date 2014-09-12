logger = require '../config/logger'
pack = require '../../package.json'
routes = require '../config/routes'

module.exports = (app) ->
  app.get routes.version, (req, res) ->
    logger.info "version info"
    res.send("#{pack.name}: #{pack.version}")
