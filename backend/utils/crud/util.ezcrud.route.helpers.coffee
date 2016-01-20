{methodExec} = require '../util.route.helpers'
factory = require '../util.factory'
logger = require '../../config/logger'

class Crud
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
    # use fat arrow?
    self = @
    methodExec req,
      GET: () ->
        self.svc.getById(req.params.id)
      PUT: () ->
        self.svc.update(req.params.id, req.body)
      POST: () ->
        self.svc.upsert(req.params.id, req.body)
      DELETE: () ->
        self.svc.delete(req.params.id, req.body)


module.exports =
  Crud:Crud
  crud: factory(Crud)
