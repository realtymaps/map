logger = require '../config/logger'
auth = require '../utils/util.auth'
loaders = require '../utils/util.loaders'
_ = require 'lodash'
path = require 'path'
Promise = require 'bluebird'
validation = require '../utils/util.validation'
ExpressResponse = require '../utils/util.expressResponse'
status = require '../../common/utils/httpStatus'
{PartiallyHandledError, isUnhandled, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'


module.exports = (app) ->
  for route in _.sortBy(loaders.loadRouteOptions(__dirname), 'order') then do (route) ->
    logger.infoRoute "route: #{route.moduleId}.#{route.routeId} intialized (#{route.method})"
    #DRY HANDLE FOR CATCHING COMMON PROMISE ERRORS
    wrappedHandle = (req,res, next) ->
      Promise.try () ->
       route.handle(req, res, next)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error)
      .catch (error) ->
        if isCausedBy(validation.DataValidationError, error)
          returnStatus = status.BAD_REQUEST
        else
          returnStatus = status.INTERNAL_SERVER_ERROR
        next new ExpressResponse
          alert:
            msg: error.message
          returnStatus
    app[route.method](route.path, route.middleware..., wrappedHandle)

  logger.info '\n'
  logger.info 'available routes: '
  paths = {}
  for routerEntry in app._router.stack when routerEntry?.route?
    methods = paths[routerEntry.route.path] || []
    paths[routerEntry.route.path] = methods.concat(_.keys(routerEntry.route.methods))

  for path,methods of paths
    logger.info path, '(' + (if methods.length >= 25 then 'all' else methods.join(',')) + ')'
