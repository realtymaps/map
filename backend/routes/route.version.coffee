logger = require '../config/logger'
pack = require '../../package.json'
routes = require '../../common/config/routes'

module.exports = (app) ->
  version = "#{pack.name}: #{pack.version}"
  logger.infoRoute 'route.version', routes.version
  logger.debug version

  app.get 'version', (req, res) ->
    logger.info "sending version info #{version}"
    res.send version
