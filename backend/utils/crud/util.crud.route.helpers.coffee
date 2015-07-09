{methodExec} = require '../util.route.helpers'
factory = require '../util.factory'
logger = require '../../config/logger'
BaseObject = require '../../../common/utils/util.baseObject'
_ = require 'lodash'

#TODO: Break Root, and byId into classes so their functionality can be overriden
# this would be useful for UseCrud on sub routes (permissions).
# as you can see there is lots of cut and paste due to some inflexibility here.
class Crud extends BaseObject
  constructor: (@svc) ->
    unless @svc?
      throw '@svc must be defined'

    # logger.debug Object.keys @
    # logger.functions @

  root: (req, res, next) =>
    self = @
    methodExec req,
      GET: () ->
        self.svc.getAll()

      POST: () -> #create
        self.svc.create(req.body)

  byId: (req, res, next) =>
    self = @
    methodExec req,
      GET: () ->
        self.svc.getById(req.params.id)
      POST: () ->
        self.svc.create(req.body, req.params.id)
      DELETE: () ->
        self.svc.delete(req.params.id)
      PUT: () ->
        self.svc.update(req.params.id, req.body)

  methodExec: methodExec

  base: () ->
    super([Crud,@].concat(_.toArray arguments)...)


class RouteCrud extends Crud
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

module.exports =
  Crud:Crud
  crud: factory(Crud)
  RouteCrud: RouteCrud
  routeCrud: factory(RouteCrud)
