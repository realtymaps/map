logger = require '../config/logger'
auth = require '../utils/util.auth'
loaders = require '../utils/util.loaders'
_ = require 'lodash'
path = require 'path'

module.exports = (app) ->
  _.forEach _.sortBy(loaders.loadRouteOptions(__dirname), 'order'), (route) ->
    logger.infoRoute "route: #{route.moduleId}.#{route.routeId} intialized (#{route.method})"
    app[route.method](route.path, route.middleware..., route.handle)

  logger.info '\n'
  logger.info "available routes: "
  paths = {}
  app._router.stack.filter((r) ->
    r?.route?
  ).forEach (r) ->
    methods = paths[r.route.path] || []
    paths[r.route.path] = methods.concat(_.keys(r.route.methods))

  _.forEach paths, (methods, path) ->
    logger.info path, '(' + (if methods.length >= 25 then 'all' else methods.join(',')) + ')'
