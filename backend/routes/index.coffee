logger = require('../config/logger').spawn('backend:routes:index')
auth = require '../utils/util.auth'
loaders = require '../utils/util.loaders'
_ = require 'lodash'
path = require 'path'
Promise = require 'bluebird'
validation = require '../utils/util.validation'
ExpressResponse = require '../utils/util.expressResponse'
status = require '../../common/utils/httpStatus'
{PartiallyHandledError, isUnhandled, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
{InValidEmailError, InActiveUserError} = require '../utils/errors/util.errors.userSession'
{ValidateEmailHashTimedOutError} = require '../utils/errors/util.errors.email'

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
    logger.debug 'CLS: Context exited'

module.exports = (app) ->
  for route in _.sortBy(loaders.loadRouteOptions(__dirname), 'order') then do (route) ->
    # logger.debug "route: #{route.moduleId}.#{route.routeId} intialized (#{route.method})"
    #DRY HANDLE FOR CATCHING COMMON PROMISE ERRORS
    wrappedHandle = (req,res, next) ->
      wrappedCLS req,res, ->
        Promise.try () ->
          route.handle(req, res, next)
        .catch isUnhandled, (error) ->
          throw new PartiallyHandledError(error)
        .catch (error) ->
          if isCausedBy(validation.DataValidationError, error) or
          isCausedBy(ValidateEmailHashTimedOutError, error)
            returnStatus = status.BAD_REQUEST
          if isCausedBy(InValidEmailError, error) or
          isCausedBy(InActiveUserError, error)
            returnStatus = status.UNAUTHORIZED
          else
            returnStatus = status.INTERNAL_SERVER_ERROR
          next new ExpressResponse
            alert:
              msg: error.message
            returnStatus
    app[route.method](route.path, route.middleware..., wrappedHandle)

  paths = {}
  for routerEntry in app._router.stack when routerEntry?.route?
    methods = paths[routerEntry.route.path] || []
    paths[routerEntry.route.path] = methods.concat(_.keys(routerEntry.route.methods))

  logger.info "available routes: #{Object.keys(paths).length}"
  for path,methods of paths
    logger.debug.green path, ' [' + (if methods.length >= 25 then 'all' else methods.join(',')).toUpperCase() + ']'
