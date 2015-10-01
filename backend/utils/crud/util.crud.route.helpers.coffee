{methodExec} = require '../util.route.helpers'
factory = require '../util.factory'
logger = require '../../config/logger'
BaseObject = require '../../../common/utils/util.baseObject'
ExpressResponse = require '../util.expressResponse'
_ = require 'lodash'
{PartiallyHandledError, isUnhandled} = require '../util.partiallyHandledError'

class Crud extends BaseObject
  constructor: (@svc, @paramIdKey = 'id', @name = '') ->
    unless @svc?
      throw new Error("#{@name} @svc must be defined.")
    unless @paramIdKey?
      throw new Error("#{@name} @paramIdKey must be defined")
    @init()

  onError: (next, error) ->
    if isUnhandled(error)
      logger.error("Crud error: #{error.stack||error}")
    next new ExpressResponse
      alert:
        msg: error.message
      500

  #intended available overrides
  init: (@doLogQuery = false, @safe = undefined) =>
    @

  rootGET: (req, res, next) =>
    @svc.getAll(req.query, @doLogQuery)
    .catch _.partial(@onError, next)

  rootPOST: (req, res, next) =>
    @svc.create(req.body, undefined, @doLogQuery)
    .catch _.partial(@onError, next)

  byIdGET: (req, res, next) =>
    @svc.getById(req.params[@paramIdKey], @doLogQuery)
    .catch _.partial(@onError, next)

  byIdPOST: (req, res, next) =>
    @svc.create(req.body, req.params[@paramIdKey], undefined, @doLogQuery)
    .catch _.partial(@onError, next)

  byIdDELETE: (req, res, next) =>
    @svc.delete(req.params[@paramIdKey], @doLogQuery)
    .catch _.partial(@onError, next)

  byIdPUT: (req, res, next) =>
    @svc.update(req.params[@paramIdKey], req.body, @safe, @doLogQuery)
    .catch _.partial(@onError, next)
  #end intended overrides

  #sugar interface
  root: (req, res, next) =>
    self = @
    @methodExec req,
      GET: () ->
        self.rootGET(req, res, next)
      POST: () ->
        self.rootPOST(req, res, next)

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

  methodExec: methodExec

  base: () ->
    super([Crud,@].concat(_.toArray arguments)...)

class HasManyCrud extends Crud
  constructor: (svc, paramIdKey, @rootGETKey, name) ->
    super(svc, paramIdKey, name)
    unless @rootGETKey?
      throw new Error('@rootGETKey must be defined')

  rootGET: (req, res, next) =>
    @svc.getAll(_.set({}, @rootGETKey, req.params.id), @doLogQuery)

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
