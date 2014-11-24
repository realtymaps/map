logger = require '../config/logger'
pack = require '../../package.json'
backendRoutes = require '../../common/config/routes.backend.coffee'


version =
  app: pack.name
  version: pack.version
versionJSON = JSON.stringify version

module.exports = (app) ->
  logger.infoRoute 'route.version', backendRoutes.version
  logger.debug 'version: ' + versionJSON

  app.get backendRoutes.version, (req, res) ->
    logger.info "sending version info #{versionJSON}"
    res.send version
