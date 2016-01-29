util = require 'util'
_ = require 'lodash'
logger = require('../../config/logger').spawn('ezcrud:route')
{methodExec, handleQuery} = require '../util.route.helpers'
factory = require '../util.factory'
RouteCrudError = require('../errors/util.errors.crud').RouteCrudError
{validateAndTransform, defaultRequestTransforms, falsyDefaultTransformsToNoop} = require '../util.validation'

class RouteCrud
  constructor: (@svc, options = {}) ->
    @debug = () ->
    if options.debugNS and _.isString options.debugNS
      @debugLogger = logger.spawn options.debugNS
      @debug = (msg) => @debugLogger.debug msg
    @enableUpsert = options.enableUpsert ? false
    unless @svc?
      throw new RouteCrudError('@svc must be defined')

    #essentially clone the parts of a request we want to not mutate it
    @reqTransforms = options.reqTransforms ? defaultRequestTransforms()
    #this is an example, the rest can be filled in by an implementation or derived class
    @rootGETTransforms = options.rootGETTransforms ? defaultRequestTransforms()
    @debug "Crud route instance made with options: #{util.inspect(options, false, 0)}"

  # Public: validRequest a request via transforms
  #
  # * `req`           request as {object}.
  # * `crudMethodStr` The crud method transform to call as {string}.
  #
  # Returns the tReq (TransformedRequest) as `Promise`.
  validRequest: (req, crudMethodStr) =>
    specificTransforms = @[crudMethodStr + 'Transforms']
    for transforms in [@reqTransforms, specificTransforms]
      falsyDefaultTransformsToNoop(transforms) if transforms?
    validateAndTransform req, @reqTransforms
    .then (tReq) =>
      @debug "root: tReq: #{JSON.stringify tReq}"
      if specificTransforms
        return validateAndTransform tReq, specificTransforms
      tReq

  exec: (req, crudMethodStr) =>
    @debug req.originalUrl if req.originalUrl
    @validRequest(req, crudMethodStr).then (tReq) ->
      tReq

  # allows leveraging centralized route handling if desired
  custom: (data, res) ->
    @debug "Using custom route"
    @_wrapRoute data, res

  # wrappers for route centralization and mgmt
  _wrapRoute: (data, res) ->
    @debug "Handling query"
    handleQuery data, res

  getQuery: (req, crudMethodStr) =>
    @debug "req.params=#{JSON.stringify(req.params)}"
    @debug "req.body=#{JSON.stringify(req.body)}"
    @debug "req.method=#{req.method}"
    @exec(req, crudMethodStr).then (tReq) ->
      query = _.merge({}, tReq.params, tReq.body)
      query

  # some other 3rd party crud libraries consolidate params & body for brevity and
  #   simplicity (perhaps for one example multi-pk handling) so lets do that here
  root: (req, res, next) =>
    methodExec req,
      GET: () =>
        @getQuery(req, 'rootGET').then (query) =>
          @_wrapRoute @svc.getAll(query), res
      POST: () =>
        @getQuery(req, 'rootPOST').then (query) =>
          @_wrapRoute @svc.create(query), res
    , next

  byId: (req, res, next) =>
    methodExec req,
      GET: () =>
        @getQuery(req, 'byIdGET').then (query) =>
          @_wrapRoute @svc.getById(query), res
      PUT: () =>
        @getQuery(req, 'byIdPUT').then (query) =>
          @_wrapRoute @svc.update(query), res

      # leverages option for upsert
      POST: () =>
        @getQuery(req, 'byIdPOST').then (query) =>
          if @enableUpsert then return @_wrapRoute @svc.upsert(query), res
          return @_wrapRoute @svc.create(query), res
      DELETE: () =>
        @getQuery(req, 'byIdDELETE').then (query) =>
          @_wrapRoute @svc.delete(query), res
    , next

module.exports = RouteCrud
