_ = require 'lodash'
Promise = require 'bluebird'
profileUtil = require '../../common/utils/util.profile'
httpStatus = require '../../common/utils/httpStatus'
DataValidationError = require './errors/util.error.dataValidation'
{MissingVarError, UpdateFailedError} = require './errors/util.errors.crud'
ExpressResponse = require './util.expressResponse'
url = require 'url'
logger = require('../config/logger').spawn('util.route.helpers')
clsFactory = require './util.cls'
analyzeValue = require '../../common/utils/util.analyzeValue'


class CurrentProfileError extends Error
class NotFoundError extends Error

methodExec = (req, methods, next) ->
  if !methods[req.method]
    return next new ExpressResponse({alert: {msg: "HTTP METHOD: #{req.method} not supported for route."}}, {quiet: quiet, status: httpStatus.BAD_REQUEST})
  methods[req.method]()

currentProfile = (req) ->
  try
    req ?= clsFactory().namespace.get 'req'
    profileUtil.currentProfile(req.session)
  catch error
    throw new CurrentProfileError(error.message)

mergeHandles = (handles, config) ->
  for key of config
    _.extend config[key],
      handle: unless config[key].handle? then handles[key] else handles[config[key].handle]
  config

handleQuery = (q, res, lHandleQuery) ->
  if lHandleQuery == false
    return q

  if _.isFunction lHandleQuery
    return lHandleQuery(q)

  #if we have a stream avail pipe it
  if q?.stringify? and _.isFunction q.stringify
    return q.stringify().pipe(res)

  q.then (result) ->
    Promise.try () ->
      res.json(result)
    .catch TypeError, (err) ->
      logger.error("#############  Circular reference detected in JSON response?  #############\n#{analyzeValue.getSimpleMessage(result)}")
      throw err

handleRoute = (req, res, next, toExec, isDirect) ->
  Promise.try () ->
    if isDirect
      return toExec(req, res, next)

    handleQuery toExec(req, res, next), res
  .catch DataValidationError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})
  .catch MissingVarError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})
  .catch UpdateFailedError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: err.quiet})
  .catch (err) ->
    if !err.quiet
      logger.error analyzeValue.getSimpleDetails(err)
    next(err)

wrapHandleRoutes = ({handles, isDirect}) ->
  for key, origFn of handles
    do (key, origFn) ->
      handles[key] = (req, res, next) ->
        handleRoute req, res, next, origFn, isDirect
  handles

#http://stackoverflow.com/questions/10183291/how-to-get-the-full-url-in-express
fullUrl = (req, pathname) ->
  url.format
    protocol: req.protocol,
    host: req.get('host'),
    pathname: pathname or req.originalUrl

clsFullUrl = (pathname) ->
  space = clsFactory().namespace
  req = space.get 'req'
  fullUrl req, pathname

module.exports =
  methodExec: methodExec
  currentProfile: currentProfile
  CurrentProfileError: CurrentProfileError
  mergeHandles: mergeHandles
  NotFoundError: NotFoundError
  handleQuery: handleQuery
  handleRoute: handleRoute
  wrapHandleRoutes: wrapHandleRoutes
  fullUrl: fullUrl
  clsFullUrl: clsFullUrl
