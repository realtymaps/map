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
  _.forEach _.sortBy(loaders.loadRouteOptions(__dirname), 'order'), (route) ->
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
  app._router.stack.filter((r) ->
    r?.route?
  ).forEach (r) ->
    methods = paths[r.route.path] || []
    paths[r.route.path] = methods.concat(_.keys(r.route.methods))

  _.forEach paths, (methods, path) ->
    logger.info path, '(' + (if methods.length >= 25 then 'all' else methods.join(',')) + ')'
