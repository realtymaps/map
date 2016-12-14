_ = require 'lodash'
Promise = require 'bluebird'
httpStatus = require '../../common/utils/httpStatus'
DataValidationError = require './errors/util.error.dataValidation'
{MissingVarError, UpdateFailedError} = require './errors/util.errors.crud'
ExpressResponse = require './util.expressResponse'
url = require 'url'
logger = require('../config/logger').spawn('util.route.helpers')
clsFactory = require './util.cls'
analyzeValue = require '../../common/utils/util.analyzeValue'

class NotFoundError extends Error

methodExec = (req, methods, next) ->
  if !methods[req.method]
    #TODO: should quiet come from params, query or body?
    return next new ExpressResponse({alert: {msg: "HTTP METHOD: #{req.method} not supported for route."}}, {quiet: false, status: httpStatus.BAD_REQUEST})
  methods[req.method]()

mergeHandles = (handles, config, options) ->
  loggerNS = if options?.debugNS then logger.spawn(options.debugNS) else logger

  loggerNS.debug -> "mergeHandles, keys:\n#{JSON.stringify(Object.keys(handles))}"
  loggerNS.debug -> "mergeHandles, config:\n#{JSON.stringify(config)}"
  for key of config
    _.extend config[key],
      handle: if config[key].handle? then handles[config[key].handle] else handles[key]
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
      logger.debug () -> "#{res.req.url} response json:"
      logger.debug () -> "#{JSON.stringify(result)}"  # this will err if circular, caught below, but url is still display from prev line for route check
      res.json(result)
    .catch TypeError, (err) ->
      logger.error("####        Circular reference detected in JSON response?         ####")
      logger.error("\tEnsure that route `#{res.req.url}` is not processing an Express Response,")
      logger.error("\tsuch as `req.json`, since that is already handled here.")
      logger.error("#{analyzeValue.getSimpleMessage(result)}")
      throw err

# TODO: Could probably be replaced by handleQuery
handleRoute = (req, res, next, toExec, isDirect) ->
  Promise.try () ->
    if isDirect
      return toExec(req, res, next)
    handleQuery toExec(req, res, next), res

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
  mergeHandles: mergeHandles
  NotFoundError: NotFoundError
  handleQuery: handleQuery
  handleRoute: handleRoute
  fullUrl: fullUrl
  clsFullUrl: clsFullUrl
