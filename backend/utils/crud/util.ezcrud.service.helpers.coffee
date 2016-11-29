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

    # reteurnKnex flag activates the CRUD handlers below to return a {knex: <query>} object
    @returnKnex = options.returnKnex ? false
    # idKeys format here helps multi-pk support
    @idKeys = options.idKeys ? ['id']
    @idKeys = [@idKeys] unless _.isArray @idKeys
    @logger.debug () => "Crud service using ids: #{@idKeys}"
    unless _.isFunction @dbFn
      throw new ServiceCrudError('dbFn must be a knex function')
    @logger.debug () -> "Crud service instance made with options: #{util.inspect(options, false, 0)}"

  # helpers for query / id mgmt
  _getIdObj: (sourceObj) =>
    keys = _.merge(_.zipObject(@idKeys), _.pick(sourceObj, @idKeys))
    @logger.debug () -> "_getIdObj(), keys=#{JSON.stringify(keys)}"
    keys

  _hasIdKeys: (testObj) ->
    @logger.debug () -> "_hasIdKeys:"
    @logger.debug () => "idKeys=#{@idKeys}"
    @logger.debug () -> "testObj=#{testObj}"
    _.every @idKeys, _.partial(_.has, testObj)

  # In order to leverage centralized query handling (error catching etc) queries
  #   should be routed through this helper method.
  # As things may grow on this class, this can hold any shared, central logic pertinent to the 'custom' scheme
  #   that we develop in the future
  custom: (query) ->
    @logger.debug () -> "Using custom query"
    @_wrapQuery query

  # intermediate function to flag _wrapQuery to return unevaluated knex
  exposeKnex: () ->
    @returnKnexTempFlag = true
    @logger.debug () -> "Flagged to return knex object, use `.knex` handle of returned object"
    @

  # centralized handling, such as catching errors, for all queries including custom ones
  _wrapQuery: (query, options) ->
    @logger.debug () -> query.toString()

    # return an objectified handle to knex obj if flagged
    if @returnKnex or @returnKnexTempFlag or options?.returnKnex
      @returnKnexTempFlag = false
      return {knex: query} # exposes unevaluated knex

    if options?.returning?
      query.returning(options.returning)

    # evaluate
    query.then (result) ->
      result
    .catch isUnhandled, (error) ->
      throw new ServiceCrudError(error, "Error evaluating query: #{query}")

  getAll: (entity = {}, options = {}) ->
    @logger.debug () -> "getAll() arguments: entity=#{util.inspect(entity,false,0)}, options=#{util.inspect(options,false,0)}"
    query = options.query ? @dbFn()
    @_wrapQuery(sqlHelpers.buildQuery(knex: query, entity: entity), options)

  create: (entity, options = {}) ->
    @logger.debug () -> "create() arguments: entity=#{util.inspect(entity,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapQuery((options.query ? @dbFn()).insert(sqlHelpers.safeJsonEntity(entity)), options)

  # implies restrictions and forces on id matches
  getById: (entity, options = {}) ->
    @logger.debug () -> "getById() arguments: entity=#{util.inspect(entity,false,0)}, options=#{util.inspect(options,false,0)}"

    # allow `entity` to represent a primitive
    ids = if _.isObject(entity) or @idKeys.length > 1 then entity else {"#{@idKeys[0]}": entity}
    throw new ServiceCrudError("getById on #{@dbFn.tableName}: required id fields `#{@idKeys}` missing") unless @_hasIdKeys ids

    @logger.debug () -> "ids: #{JSON.stringify(ids)}"
    @_wrapQuery((options.query ? @dbFn()).where(ids), options)

  update: (entity, options = {}) ->
    @logger.debug () -> "update() arguments: entity=#{util.inspect(entity,false,0)}, options=#{util.inspect(options,false,0)}"
    throw new ServiceCrudError("update on #{@dbFn.tableName}: required id fields `#{@idKeys}` missing") unless @_hasIdKeys entity
    ids = @_getIdObj entity
    entity = _.omit entity, @idKeys
    @logger.debug () -> "ids: #{JSON.stringify(ids)}"
    @logger.debug () -> "entity: #{JSON.stringify(entity)}"
    @_wrapQuery (options.query ? @dbFn()).where(ids).update(sqlHelpers.safeJsonEntity(entity)), options

  upsert: (entity, options = {}) ->
    @logger.debug () -> "upsert() arguments: entity=#{util.inspect(entity,false,0)}, options=#{util.inspect(options,false,0)}"
    ids = @_getIdObj entity
    entity = _.omit entity, @idKeys
    @logger.debug () -> "ids: #{JSON.stringify(ids)}"
    @logger.debug () -> "entity: #{JSON.stringify(entity)}"
    upsertQuery = sqlHelpers.buildUpsertBindings idObj:ids, entityObj: sqlHelpers.safeJsonEntity(entity), tableName: @dbFn.tableName
    @_wrapQuery((options.query ? @dbFn()).raw(upsertQuery.sql, upsertQuery.bindings), options)

  delete: (entity, options = {}) ->
    @logger.debug () -> "delete() arguments: entity=#{util.inspect(entity,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapQuery((options.query ? @dbFn()).where(entity).delete(), options)

module.exports = ServiceCrud
