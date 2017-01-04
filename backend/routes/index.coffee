logger = require('../config/logger').spawn('routes:index')
loaders = require '../utils/util.loaders'
_ = require 'lodash'
path = require 'path'
Promise = require 'bluebird'
{isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
routeHelpers = require '../utils/util.route.helpers'

config = require '../config/config'
uuid = require '../utils/util.uuid'
cls = require 'continuation-local-storage'
namespace = cls.createNamespace config.NAMESPACE

###
ability to get request and transaction id without callback hell
http://stackoverflow.com/questions/12575858/is-it-possible-to-get-the-current-request-that-is-being-served-by-node-js
DOMAINS ARE deprecated so we are going with continuation-local-storage instead. Which appears to be cleaner anyhow.
###
wrappedCLS = (req, res, promisFnToWrap) ->
  ctx = namespace.createContext()
  namespace.enter(ctx)
  namespace.set 'transactionId', uuid.genUUID()
  namespace.set 'req', req
  # logger.debug namespace, true
  promisFnToWrap()
  .finally ->
    namespace.exit(ctx)
    logger.spawn('cls').debug 'CLS: Context exited'

module.exports = (app, sessionMiddlewares) ->
  for route in _.sortBy(loaders.loadRouteOptions(__dirname), 'order') then do (route) ->
    logger.spawn('init').debug "route: #{route.moduleId}.#{route.routeId} initialized (#{route.method}) #{if route.handleQuery then 'handleQuery' else ''}"
    #DRY HANDLE FOR CATCHING COMMON PROMISE ERRORS
    wrappedHandle = (req,res, next) ->
      wrappedCLS req,res, ->
        Promise.try () ->
          logger.debug () -> "Express router processing  #{req.method} #{req.url}..."
          if route.handleQuery
            result = route.handle(req, res, next)
            routeHelpers.handleQuery result, res
          else
            route.handle(req, res, next)
        .catch isUnhandled, (error) ->
          error.routeInfo = route
          throw error
        .catch (error) ->
          next(error)
    # we only add per-route middleware to handle login and permissions checking -- that means only the routes with such
    # middleware actually need to use the session stuff, and we can avoid setting session cookies on other routes
    if route.middleware.length > 0
      middlewares = [].concat(sessionMiddlewares, route.middleware)
    else
      middlewares = []
    app[route.method](route.path, middlewares..., wrappedHandle)

  paths = {}
  for routerEntry in app._router.stack when routerEntry?.route?
    methods = paths[routerEntry.route.path] || []
    paths[routerEntry.route.path] = methods.concat(_.keys(routerEntry.route.methods))

  logger.info "available routes: #{Object.keys(paths).length}"
  for path,methods of paths
    logger.debug.green path, ' [' + (if methods.length >= 25 then 'all' else methods.join(',')).toUpperCase() + ']'
