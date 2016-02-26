util = require 'util'
_ = require 'lodash'
_logger = require('../../config/logger').spawn('ezcrud:route')
{methodExec, handleQuery} = require '../util.route.helpers'
RouteCrudError = require('../errors/util.errors.crud').RouteCrudError
{
  validateAndTransform
  validateAndTransformRequest
  defaultRequestTransforms
  falsyDefaultTransformsToNoop
} = require '../util.validation'

class RouteCrud
  constructor: (@svc, options = {}) ->
    unless @svc?
      throw new RouteCrudError('@svc must be defined')

    @logger = _logger
    if @svc.dbFn?.tableName
      @logger = @logger.spawn(@svc.dbFn?.tableName)
    if options.debugNS
      @logger = @logger.spawn(options.debugNS)
    @enableUpsert = options.enableUpsert ? false

    #essentially clone the parts of a request we want to not mutate it
    @reqTransforms = options.reqTransforms ? defaultRequestTransforms()
    @initializeTransforms 'root', options, ['GET', 'POST']
    @initializeTransforms 'byId', options

    @logger.debug () -> "Crud route instance made with options: #{util.inspect(options, false, 0)}"


  initializeTransforms: (transformType, options, methods = ['GET', 'POST', 'PUT', 'DELETE']) =>
    methods.forEach (meth) =>
      transformName = "#{transformType}#{meth}Transforms"
      @[transformName] = options[transformName] ? defaultRequestTransforms()

  # Public: validRequest a request via transforms
  #
  # * `req`           request as {object}.
  # * `crudMethodStr` The crud method transform to call as {string}.
  #
  # Returns the tReq (TransformedRequest) as `Promise`.
  validRequest: (req, crudMethodStr) =>
    transformName = crudMethodStr + 'Transforms'
    specificTransforms = @[transformName]
    @logger.debug.magenta "might have: #{transformName}"

    for transforms in [@reqTransforms, specificTransforms]
      falsyDefaultTransformsToNoop(transforms) if transforms?
    validateAndTransform req, @reqTransforms
    .then (tReq) =>
      @logger.debug () -> "root: tReq: #{JSON.stringify tReq}"
      if specificTransforms
        @logger.debug "attempting: #{transformName}"
        return validateAndTransform tReq, specificTransforms
      tReq

  logRequest: (req, addMsg, type = 'req') =>
    if addMsg
      @logger.debug.cyan(addMsg)
    @logger.debug () -> "#{type}.params=#{JSON.stringify(req.params)}"
    @logger.debug () -> "#{type}.query=#{JSON.stringify(req.query)}"
    @logger.debug () -> "#{type}.body=#{JSON.stringify(req.body)}"
    @logger.debug () -> "#{type}.method=#{req.method}"
    return

  exec: (req, crudMethodStr) =>
    if req.originalUrl
      @logger.debug req.originalUrl
    @validRequest(req, crudMethodStr).then (tReq) ->
      tReq

  # allows leveraging centralized route handling if desired
  custom: (data, res) ->
    @logger.debug "Using custom route"
    @_wrapRoute data, res

  # wrappers for route centralization and mgmt
  _wrapRoute: (q, res, lHandleQuery) =>
    @logger.debug "Handling query"
    handleQuery q, res, lHandleQuery

  getQuery: (req, crudMethodStr) =>
    @logRequest req, 'initial req'
    @exec(req, crudMethodStr).then (tReq) =>
      @logRequest tReq, 'transformed tReq', 'tReq'
      query = _.merge({}, tReq.params, tReq.body, tReq.query)
      query

  rootGET: ({req, res, next, lHandleQuery}) =>
    @getQuery(req, 'rootGET').then (query) =>
      @_wrapRoute @svc.getAll(query), res, lHandleQuery

  rootPOST: ({req, res, next, lHandleQuery}) =>
    @logger.debug () -> "POST, @enableUpsert:#{@enableUpsert}"
    @getQuery(req, 'rootPOST').then (query) =>
      if @enableUpsert then return @_wrapRoute @svc.upsert(query), res
      return @_wrapRoute @svc.create(query), res, lHandleQuery

  byIdGET: ({req, res, next, lHandleQuery}) =>
    @getQuery(req, 'byIdGET').then (query) =>
      @_wrapRoute @svc.getById(query), res, lHandleQuery

  byIdPUT: ({req, res, next, lHandleQuery}) =>
    @getQuery(req, 'byIdPUT').then (query) =>
      @_wrapRoute @svc.update(query), res, lHandleQuery

  byIdPOST: ({req, res, next, lHandleQuery}) =>
    @logger.debug () -> "POST, @enableUpsert:#{@enableUpsert}"
    @getQuery(req, 'byIdPOST').then (query) =>
      if @enableUpsert then return @_wrapRoute @svc.upsert(query), res
      return @_wrapRoute @svc.create(query), res, lHandleQuery

  byIdDELETE: ({req, res, next, lHandleQuery}) =>
    @getQuery(req, 'byIdDELETE').then (query) =>
      @_wrapRoute @svc.delete(query), res,

  # some other 3rd party crud libraries consolidate params & body for brevity and
  #   simplicity (perhaps for one example multi-pk handling) so lets do that here
  root: (req, res, next) =>
    methodExec req,
      GET: () =>
        @rootGET {req, res, next}
      POST: () =>
        @rootPOST {req, res, next}
    , next

  byId: (req, res, next) =>
    methodExec req,
      GET: () =>
        @byIdGET {req, res, next}
      PUT: () =>
        @byIdPUT {req, res, next}

      # leverages option for upsert
      POST: () =>
        @byIdPOST {req, res, next}
      DELETE: () =>
        @byIdDELETE {req, res, next}
    , next

module.exports = RouteCrud
