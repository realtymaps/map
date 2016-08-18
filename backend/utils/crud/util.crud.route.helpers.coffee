{methodExec} = require '../util.route.helpers'
factory = require '../util.factory'
logger = require('../../config/logger').spawn('crud:routeHelpers')
BaseObject = require '../../../common/utils/util.baseObject'
_ = require 'lodash'
NamedError = require '../errors/util.error.named'
{validateAndTransform, defaultRequestTransforms, falsyDefaultTransformsToNoop} = require '../util.validation'
{handleQuery} = require '../util.route.helpers'

class Crud extends BaseObject
  # consider moving some of these params into opts
  constructor: (@svc, @paramIdKey = 'id', @name = 'Crud', @doLogRequest, opts={}) ->
    unless @svc?
      throw new NamedError(@name, {quiet: opts.quiet}, "@svc must be defined.")
    #essentially clone the parts of a request we want to not mutate it
    @reqTransforms = defaultRequestTransforms()
    #this is an example, the rest can be filled in by an implementation or derived class
    @rootGETTransforms = defaultRequestTransforms()

    @init()

  maybeLogRequest: (req, description = '') =>
    if description.length
      description += ':'
    # logger.debug "doLogRequest: #{doLogRequest}"
    return unless @doLogRequest
    switch typeof @doLogRequest
      when 'boolean' then logger.debug("#{description}"); logger.debug req
      when 'string' then logger.debug "#{description} #{@name}: #{@doLogRequest}: #{JSON.stringify req[@doLogRequest]}"
      when 'object'
        if @doLogRequest instanceof Array
          toLog = {}
          @doLogRequest.forEach (k) ->
            toLog[k] = req[k]
          logger.debug "#{description} #{@name}: #{JSON.stringify toLog}"
      else return
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
      logger.debug "#{@name}: root: tReq: #{JSON.stringify tReq}"
      if specificTransforms
        return validateAndTransform tReq, specificTransforms
      tReq

  #intended available overrides
  init: (@doLogQuery = false, @safe = undefined) =>
    @

  exec: (crudMethodStr, req, res, next) =>
    @maybeLogRequest req, 'req'
    logger.debug req.originalUrl if req.originalUrl
    @validRequest(req, crudMethodStr).then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
      tReq

  rootGET: (req, res, next) =>
    @exec('rootGET', req, res, next).then (tReq) =>
      @svc.getAll(_.merge({}, tReq.query, tReq.params), @doLogQuery)

  rootPOST: (req, res, next) =>
    @exec('rootPOST', req, res, next).then (tReq) =>
      @svc.create(tReq.body, undefined, @doLogQuery)

  byIdGET: (req, res, next) =>
    @exec('byIdGET', req, res, next).then (tReq) =>
      @svc.getById(tReq.params, @doLogQuery)

  byIdPOST: (req, res, next) =>
    @exec('byIdPOST', req, res, next).then (tReq) =>
      @svc.create(tReq.body, tReq.params, undefined, @doLogQuery)

  byIdDELETE: (req, res, next) =>
    @exec('byIdDELETE', req, res, next).then (tReq) =>
      @svc.delete(tReq.params, @doLogQuery, tReq.query, @safe)

  byIdPUT: (req, res, next) =>
    @exec('byIdPUT', req, res, next).then (tReq) =>
      @svc.update(tReq.params, tReq.body, @safe, @doLogQuery)
  #end intended overrides

  #sugar interface
  root: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.rootGET(req, res, next)
      POST: () ->
        self.rootPOST(req, res, next)
    , next

  #sugar interface
  byId: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.byIdGET(req, res, next)
      POST: () ->
        self.byIdPOST(req, res, next)
      DELETE: () ->
        self.byIdDELETE(req, res, next)
      PUT: () ->
        self.byIdPUT(req, res, next)
    , next

  methodExec: methodExec

  base: () ->
    super([Crud,@].concat(_.toArray arguments)...)

class HasManyCrud extends Crud
  constructor: (svc, paramIdKey, @rootGETKey, name = 'HasManyRouteCrud', doLogRequest, opts={}) ->
    # console.log name
    super(svc, paramIdKey, name, doLogRequest)
    unless @rootGETKey?
      throw new NamedError(@name, {quiet: opts.quiet}, '@rootGETKey must be defined')

  rootGET: (req, res, next) =>
    @maybeLogRequest req, 'req'
    @validRequest(req, 'rootGET').then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
      @svc.getAll(_.set(tReq.query, @rootGETKey, tReq.params.id), @doLogQuery)


wrapRoutesTrait = (baseKlass) ->
  class RoutesTrait extends baseKlass
    handleQuery: handleQuery

    root: (req, res, next) ->
      @handleQuery super(req, res, next), res

    byId: (req, res, next) ->
      @handleQuery super(req, res, next), res

routeCruds = [Crud, HasManyCrud].map (baseKlass) ->
  wrapRoutesTrait(baseKlass)

RouteCrud = routeCruds[0]
HasManyRouteCrud = routeCruds[1]

module.exports =
  Crud:Crud
  crud: factory(Crud)
  RouteCrud: RouteCrud
  routeCrud: factory(RouteCrud)
  HasManyRouteCrud: HasManyRouteCrud
  hasManyRouteCrud: factory(HasManyRouteCrud)
  wrapRoutesTrait: wrapRoutesTrait
