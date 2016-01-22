util = require 'util'
_ = require 'lodash'
logger = require('../../config/logger').spawn('backend:ezcrud.route')
{methodExec, handleQuery} = require '../util.route.helpers'
factory = require '../util.factory'
RouteCrudError = require('../errors/util.errors.crud').RouteCrudError


class Crud
  constructor: (@svc, options = {}) ->
    @debug = (msg) -> (options.debug ? false) and logger.debug "######## RouteCrud: #{msg}"
    @enableUpsert = options.enableUpsert ? false
    unless @svc?
      throw new RouteCrudError('@svc must be defined')
    @debug "Crud route instance made with options: #{util.inspect(options, false, 0)}"

  # allows leveraging centralized route handling if desired
  custom: (data, res) ->
    @debug "Using custom route"
    @_wrapRoute data, res

  # wrappers for route centralization and mgmt
  _wrapRoute: (data, res) ->
    @debug "Handling query"
    handleQuery data, res

  _getQuery: (req) =>
    query = _.merge({}, req.params, req.body)
    @debug "req.params=#{JSON.stringify(req.params)}"
    @debug "req.body=#{JSON.stringify(req.body)}"
    @debug "req.method=#{req.method}"
    query

  # some other 3rd party crud libraries consolidate params & body for brevity and
  #   simplicity (perhaps for one example multi-pk handling) so lets do that here
  root: (req, res, next) =>
    methodExec req,
      GET: () =>
        @_wrapRoute @svc.getAll(@_getQuery(req)), res
      POST: () =>
        @_wrapRoute @svc.create(@_getQuery(req)), res
    , next

  byId: (req, res, next) =>
    methodExec req,
      GET: () =>
        @_wrapRoute @svc.getById(@_getQuery(req)), res
      PUT: () =>
        @_wrapRoute @svc.update(@_getQuery(req)), res

      # leverages option for upsert
      POST: () =>
        if @enableUpsert then return @_wrapRoute @svc.upsert(@_getQuery(req)), res
        return @_wrapRoute @svc.create(@_getQuery(req)), res
      DELETE: () =>
        @_wrapRoute @svc.delete(@_getQuery(req)), res
    , next

module.exports = Crud
