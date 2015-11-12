{methodExec} = require '../util.route.helpers'
factory = require '../util.factory'
logger = require '../../config/logger'
BaseObject = require '../../../common/utils/util.baseObject'
ExpressResponse = require '../util.expressResponse'
_ = require 'lodash'
{PartiallyHandledError, isUnhandled} = require '../errors/util.error.partiallyHandledError'
NamedError = require '../errors/util.error.named'
{validators, validateAndTransform} = require '../util.validation'
Promise = require 'bluebird'

class Crud extends BaseObject
  constructor: (@svc, @paramIdKey = 'id', @name = 'Crud', @doLogRequest) ->
    unless @svc?
      throw new NamedError(@name, "#{@name}: @svc must be defined.")
    #essentially clone the parts of a request we want to not mutate it
    @reqTransforms =
      query: validators.noop
      body: validators.noop
      params: validators.noop

    #this is an example, the rest can be filled in by an implementation or derrived class
    @rootGETTransforms =
      query: validators.noop
      body: validators.noop
      params: validators.noop

    @init()

  maybeLogRequest: (req, description) =>
    logger.debug description if description
    # logger.debug "doLogRequest: #{doLogRequest}"
    return unless @doLogRequest
    switch typeof @doLogRequest
      when 'boolean' then logger.debug req
      when 'string' then logger.debug req[@doLogRequest]
      when 'object'
        if @doLogRequest instanceof Array
          @doLogRequest.forEach (k) ->
            logger.debug "#{k}: #{JSON.stringify req[k]}"
      else return
  # Public: validRequest a reques via transforms
  #
  # * `req`           request as {object}.
  # * `crudMethodStr` The crud method tranform to call as {string}.
  #
  # Returns the tReq (TransformedRequest) as `Promise`.
  validRequest: (req, crudMethodStr) =>
    specificTransforms = @[crudMethodStr + 'Transforms']
    validateAndTransform req, @reqTransforms
    .then (tReq) ->
      logger.debug "root: tReq: #{JSON.stringify tReq}"
      if specificTransforms
        return validateAndTransform tReq, specificTransforms
      tReq

  #intended available overrides
  init: (@doLogQuery = false, @safe = undefined) =>
    @

  # validGet: (req, res, next) =>

  rootGET: (req, res, next) =>
    @maybeLogRequest req, 'req'
    @validRequest(req, 'rootGET').then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
      @svc.getAll(_.merge({}, tReq.query, tReq.params), @doLogQuery)

  rootPOST: (req, res, next) =>
    @maybeLogRequest req, 'req'
    @validRequest(req, 'rootPOST').then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
      @svc.create(tReq.body, undefined, @doLogQuery)

  byIdGET: (req, res, next) =>
    @maybeLogRequest req, 'req'
    @validRequest(req, 'byIdGET').then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
      @svc.getById(tReq.params, @doLogQuery)

  byIdPOST: (req, res, next) =>
    @maybeLogRequest req, 'req'
    @validRequest(req, 'byIdPOST').then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
      @svc.create(tReq.body, tReq.params, undefined, @doLogQuery)

  byIdDELETE: (req, res, next) =>
    @maybeLogRequest req, 'req'
    @validRequest(req, 'byIdDELETE').then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
      @svc.delete(tReq.params, @doLogQuery, tReq.query, @safe)

  byIdPUT: (req, res, next) =>
    @maybeLogRequest req, 'req'
    @validRequest(req, 'byIdPUT').then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
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
  constructor: (svc, paramIdKey, @rootGETKey, name = 'HasManyRouteCrud', doLogRequest) ->
    # console.log name
    super(svc, paramIdKey, name, doLogRequest)
    unless @rootGETKey?
      throw new NamedError(@name,'@rootGETKey must be defined')

  rootGET: (req, res, next) =>
    @maybeLogRequest req, 'req'
    @validRequest(req, 'rootGET').then (tReq) =>
      @maybeLogRequest tReq, 'tReq'
      @svc.getAll(_.set(tReq.query, @rootGETKey, tReq.params.id), @doLogQuery)

###
TODO:
- needs validation (leaving this to who actually is using it)
- needs error handling
###

wrapRoutesTrait = (baseKlass) ->
  class RoutesTrait extends baseKlass
    handleQuery: (q, res) ->
      #if we have a stream avail pipe it
      if q?.stringify? and _.isFunction q.stringify
        return q.stringify().pipe(res)

      q.then (result) ->
        res.json(result)

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
