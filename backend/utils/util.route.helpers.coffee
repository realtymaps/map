_ = require 'lodash'
Promise = require 'bluebird'
profileUtil = require '../../common/utils/util.profile'
httpStatus = require '../../common/utils/httpStatus'
DataValidationError = require './errors/util.error.dataValidation'
{MissingVarError, UpdateFailedError} = require './errors/util.errors.crud'
ExpressResponse = require './util.expressResponse'
url = require 'url'
logger = require '../config/logger'
clsFactory = require './util.cls'

class CurrentProfileError extends Error
class NotFoundError extends Error

badRequest = (msg) ->
  new ExpressResponse(alert: {msg: msg}, httpStatus.BAD_REQUEST)

methodExec = (req, methods, next) ->
  do(methods[req.method] or -> next(badRequest("HTTP METHOD: #{req.method} not supported for route.")))

currentProfile = (req) ->
  try
    profileUtil.currentProfile(req.session)
  catch e
    throw new CurrentProfileError(e.message)

mergeHandles = (handles, config) ->
  for key of config
    _.extend config[key],
      handle: unless config[key].handle? then handles[key] else handles[config[key].handle]
  config

handleQuery = (q, res) ->
  #if we have a stream avail pipe it
  if q?.stringify? and _.isFunction q.stringify
    return q.stringify().pipe(res)

  q.then (result) ->
    res.json(result)

handleRoute = (req, res, next, toExec) ->
  Promise.try () ->
    handleQuery toExec(req, res), res
  .catch DataValidationError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
  .catch MissingVarError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, httpStatus.INTERNAL_SERVER_ERROR)
  .catch UpdateFailedError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, httpStatus.INTERNAL_SERVER_ERROR)
  .catch (err) ->
    logger.error err.stack or err.toString()
    next(err)

wrapHandleRoutes = (handles) ->
  for key, origFn of handles
    do (key, origFn) ->
      handles[key] = (req, res, next) ->
        handleRoute req, res, next, origFn
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
  badRequest: badRequest
  mergeHandles: mergeHandles
  NotFoundError: NotFoundError
  handleQuery: handleQuery
  handleRoute: handleRoute
  wrapHandleRoutes: wrapHandleRoutes
  fullUrl: fullUrl
  clsFullUrl: clsFullUrl
