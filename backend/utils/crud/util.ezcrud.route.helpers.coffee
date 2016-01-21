logger = require('../../config/logger').spawn('backend:ezcrud.route')
{methodExec, handleQuery} = require '../util.route.helpers'
factory = require '../util.factory'
RouteCrudError = require('../util.errors.crud').RouteCrudError

logger.debug "\n\n######## ezcrud routes evaluated"

class Crud
  constructor: (@svc, options = {}) ->
    @debug = (msg) -> (options.debug ? false) and logger.debug "RouteCrud: #{msg}"
    unless @svc?
      throw new RouteCrudError('@svc must be defined')

    # logger.debug Object.keys @
    # logger.functions @
  custom: (req, res, next, data) =>
    @_wrapRoute 


  _wrapRoute: (req, res, next, data) =>
    handleQuery data, res


  root: (req, res, next) =>
    @debug "root(), req.params=#{req.params}"
    @debug "root(), req.body=#{req.body}"
    @debug "root(), req.method=#{req.method}"
    self = @
    methodExec req,
      GET: () ->
        self.svc.getAll()

      POST: () ->
        self.svc.create(req.body)
    , next

  byId: (req, res, next) =>
    @debug "byId(), req.params=#{req.params}"
    @debug "byId(), req.body=#{req.body}"
    @debug "byId(), req.method=#{req.method}"

    # use fat arrow below for self?
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
    , next

module.exports = Crud
  #Crud: Crud
  #crud: factory(Crud)
