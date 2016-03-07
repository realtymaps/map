util = require 'util'
_logger = require('../../config/logger').spawn('ezcrud:service')
BaseObject = require '../../../common/utils/util.baseObject'
isUnhandled = require('../errors/util.error.partiallyHandledError').isUnhandled
ServiceCrudError = require('../errors/util.errors.crud').ServiceCrudError
_ = require 'lodash'
sqlHelpers = require '../util.sql.helpers'


class ServiceCrud extends BaseObject
  constructor: (@dbFn, options = {}) ->
    @logger = _logger
    if @dbFn.tableName
      @logger = @logger.spawn(@dbFn.tableName)
    if options.debugNS
      @logger = @logger.spawn(options.debugNS)

    # reteurnKnex flag activates the CRUD handlers below to return a {knex: <transaction>} object
    @returnKnex = options.returnKnex ? false
    # idKeys format here helps multi-pk support
    @idKeys = options.idKeys ? ['id']
    @idKeys = [@idKeys] unless _.isArray @idKeys
    unless _.isFunction @dbFn
      throw new ServiceCrudError('dbFn must be a knex function')
    @logger.debug () -> "Crud service instance made with options: #{util.inspect(options, false, 0)}"

  # helpers for query / id mgmt
  _getIdObj: (sourceObj) ->
    keys = _.merge(_.zipObject(@idKeys), _.pick(sourceObj, @idKeys))
    @logger.debug () -> "_getIdObj(), keys=#{JSON.stringify(keys)}"
    keys

  _hasIdKeys: (testObj) ->
    @logger.debug () -> "_hasIdKeys:"
    @logger.debug () -> "idKeys=#{@idKeys}"
    @logger.debug () -> "testObj=#{testObj}"
    _.every @idKeys, _.partial(_.has, testObj)

  # In order to leverage centralized transaction handling (error catching etc) transactions
  #   should be routed through this helper method.
  # As things may grow on this class, this can hold any shared, central logic pertinent to the 'custom' scheme
  #   that we develop in the future
  custom: (transaction) ->
    @logger.debug () -> "Using custom transaction"
    @_wrapTransaction transaction

  # intermediate function to flag _wrapTransaction to return unevaluated knex
  exposeKnex: () ->
    @returnKnexTempFlag = true
    @logger.debug () -> "Flagged to return knex object, use `.knex` handle of returned object"
    @

  # centralized handling, such as catching errors, for all queries including custom ones
  _wrapTransaction: (transaction, options) ->
    @logger.debug () -> transaction.toString()

    # return an objectified handle to knex obj if flagged
    if @returnKnex or @returnKnexTempFlag or options?.returnKnex
      @returnKnexTempFlag = false
      return {knex: transaction} # exposes unevaluated knex

    # evaluate
    transaction.then (result) ->
      result
    .catch isUnhandled, (error) =>
      @logger.debug () -> error
      throw new ServiceCrudError(error, "Error evaluating query: #{transaction}")

  getAll: (query = {}, options = {}) ->
    @logger.debug () -> "getAll(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapTransaction(options.transaction ? sqlHelpers.buildQuery(knex: @dbFn(), entity: query), options)

  create: (query, options = {}) ->
    #TODO should there be options to handle where / orWhereIn for inserts w/o the need to override?
    @logger.debug () -> "create(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapTransaction(options.transaction ? @dbFn().insert(query), options)

  # implies restrictions and forces on id matches
  getById: (query, options = {}) =>
    # allow `query` to represent a single, simple num/str id
    query = {"#{@idKeys[0]}": query} unless _.isObject query or @idkeys.length > 1
    @logger.debug () -> "getById(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    throw new ServiceCrudError("getById on #{@dbFn.tableName}: required id fields `#{@idkeys}` missing") unless @_hasIdKeys query
    @_wrapTransaction(options.transaction ? @dbFn().where @_getIdObj query, options)

  update: (query, options = {}) ->
    @logger.debug () -> "update(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    throw new ServiceCrudError("update on #{@dbFn.tableName}: required id fields `#{@idkeys}` missing") unless @_hasIdKeys query
    ids = @_getIdObj query
    entity = _.omit query, @idKeys
    @logger.debug () -> "ids: #{JSON.stringify(ids)}"
    @logger.debug () -> "entity: #{JSON.stringify(entity)}"
    @_wrapTransaction(options.transaction ? @dbFn().where(@_getIdObj query).update(_.omit query, @idKeys), options)

  upsert: (query, options = {}) ->
    @logger.debug () -> "upsert(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    ids = @_getIdObj query
    entity = _.omit query, @idKeys
    @logger.debug () -> "ids: #{JSON.stringify(ids)}"
    @logger.debug () -> "entity: #{JSON.stringify(entity)}"

    upsertQuery = sqlHelpers.buildUpsertBindings ids, entity, @dbFn.tableName
    @_wrapTransaction(options.transaction ? @dbFn().raw(upsertQuery.sql, upsertQuery.bindings), options)

  delete: (query, options = {}) ->
    @logger.debug () -> "delete(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapTransaction(options.transaction ? @dbFn().where(query).delete(), options)

module.exports = ServiceCrud
