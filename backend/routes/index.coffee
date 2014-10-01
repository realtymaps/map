path = require 'path'
config = require '../config/config'
logger = require '../config/logger'
attachRoutes = require('../utils/util.routeLoader').loadRoutes
routes = require '../../common/config/routes'

indexFilePath = path.normalize(__filename)


module.exports = (app) ->
  attachRoutes app, indexFilePath, __dirname

  logger.infoRoute 'index', routes.index
  app.get routes.index, (req, res) ->
    frontEndIndex = "#{config.FRONTEND_ASSETS_PATH}/index.html"
    logger.route "frontEndIndex: #{frontEndIndex}"
    res.sendFile frontEndIndex

  logAllRoutes = ->
    logger.info '\n'
    logger.info "available routes: "
    app._router.stack.filter((r) ->
      r?.route?
    ).map (r) ->
      path = r.route.path
      logger.info path
      path

  logAllRoutes()
