logger = require '../config/logger'
pack = require '../../package.json'
routes = require '../../common/config/routes'

version =
  app: pack.name
  version: pack.version
versionJSON = JSON.stringify version

module.exports = (app) ->
  logger.infoRoute 'route.version', routes.version
  logger.debug 'version: ' + versionJSON

  app.get routes.version, (req, res) ->
    logger.info "sending version info #{versionJSON}"
    res.send version
