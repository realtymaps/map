path = require 'path'
config = require '../config/config'
logger = require '../config/logger'
attachRoutes = require('../utils/util.routeLoader').loadRoutes
frontendRoutes = require '../../common/config/routes.frontend.coffee'
backendRoutes = require '../../common/config/routes.backend.coffee'

indexFilePath = path.normalize(__filename)

loadMainAssets = (req, res) ->
  frontEndIndex = "#{config.FRONTEND_ASSETS_PATH}/index.html"
  logger.route "frontEndIndex: #{frontEndIndex}"
  res.sendFile frontEndIndex

module.exports = (app) ->
  attachRoutes app, indexFilePath, __dirname

  logger.infoRoute 'index', frontendRoutes.index
  app.get frontendRoutes.index, loadMainAssets

  # this wildcard fallback allows express to deal with any unknown api URL
  logger.infoRoute 'wildcard (backend)', backendRoutes.wildcard
  app.get backendRoutes.wildcard, (req, res, next) ->
    next(status: 404, message: {error: "The resource #{req.path} was not found."})

  # this wildcard fallback allows angular to deal with any URL that isn't an api URL
  logger.infoRoute 'wildcard (frontend)', frontendRoutes.wildcard
  app.get frontendRoutes.wildcard, loadMainAssets

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
