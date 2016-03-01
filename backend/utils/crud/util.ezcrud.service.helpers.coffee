util = require 'util'
_logger = require('../../config/logger').spawn('ezcrud:service')
BaseObject = require '../../../common/utils/util.baseObject'
isUnhandled = require('../errors/util.error.partiallyHandledError').isUnhandled
ServiceCrudError = require('../errors/util.errors.crud').ServiceCrudError
_ = require 'lodash'
factory = require '../util.factory'


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

  # Static function that produces an upsert query string given ids and entity of model.
  # This exposes upsert query string for any other modules to use if desired and only
  # requires ids and entity as objects (idobj helps for support on multi-id pks)
  @getUpsertQueryString: (idObj, entityObj, tableName) ->
    # "pre-process" data
    for k,v of idObj
      # upsert doesn't seem to know what to do w/ given 'null' pk
      idObj[k] = '__DEFAULT__' if !v?

    for k,v of entityObj
      # stringify any JSON data and arrays
      v = JSON.stringify(v) if _.isObject v
      # use placeholder for single quotes in strings (incl for JSON)
      v = v.replace(/'/g,'__SINGLE_QUOTE__') if _.isString v
      # use placeholder for question marks in strings
      v = v.replace(/\?/g,'__QUESTION__') if _.isString v
      entityObj[k] = v

    # some string processing to help give us good query values:
    #   util.inspect gives good array repr of entity values that can be used for sql values
    #   substring out non-JSON field brackets (to avoid risk removing brackets from json arrays)
    idKeys = "#{_.keys(idObj)}"
    entityKeys = "#{_.keys(entityObj)}"
    allKeys = "#{idKeys},#{entityKeys}"

    idValues = "#{util.inspect(_.values(idObj))}"
    idValues = idValues.substring(1,idValues.length-1)
    idValues = idValues.replace(/__SINGLE_QUOTE__/g,"''")
    idValues = idValues.replace(/\'__DEFAULT__\'/g,'DEFAULT')
    entityValues = "#{util.inspect(_.values(entityObj))}"
    entityValues = entityValues.substring(1,entityValues.length-1)
    entityValues = entityValues.replace(/__SINGLE_QUOTE__/g,"''")
    entityValues = entityValues.replace(/__QUESTION__/g,"\\?")
    allValues = "#{idValues},#{entityValues}"

    # postgresql template for raw query
    # (no real native knex support yet: https://github.com/tgriesser/knex/issues/1121)
    qstr = """
     INSERT INTO #{tableName} (#{allKeys})
      VALUES (#{allValues})
      ON CONFLICT (#{idKeys})
      DO UPDATE SET (#{entityKeys}) = (#{entityValues})
      RETURNING #{idKeys}
    """

    # "post-process" data, sanitize the resulting string above suitable as raw query
    qstr = qstr.replace(/\n/g,'')
    qstr

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
  _wrapTransaction: (transaction) ->
    @logger.debug () -> transaction.toString()

    # return an objectified handle to knex obj if flagged
    if @returnKnex or @returnKnexTempFlag
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
    @_wrapTransaction options.transaction ? @dbFn().where(query)

  create: (query, options = {}) ->
    @logger.debug () -> "create(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapTransaction options.transaction ? @dbFn().insert(query)

  # implies restrictions and forces on id matches
  getById: (query, options = {}) =>
    # allow `query` to represent a single, simple num/str id
    query = {"#{@idKeys[0]}": query} unless _.isObject query or @idkeys.length > 1
    @logger.debug () -> "getById(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    throw new ServiceCrudError("getById on #{@dbFn.tableName}: required id fields `#{@idkeys}` missing") unless @_hasIdKeys query
    @_wrapTransaction options.transaction ? @dbFn().where @_getIdObj query

  update: (query, options = {}) ->
    @logger.debug () -> "update(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    throw new ServiceCrudError("update on #{@dbFn.tableName}: required id fields `#{@idkeys}` missing") unless @_hasIdKeys query
    ids = @_getIdObj query
    entity = _.omit query, @idKeys
    @logger.debug () -> "ids: #{JSON.stringify(ids)}"
    @logger.debug () -> "entity: #{JSON.stringify(entity)}"
    @_wrapTransaction options.transaction ? @dbFn().where(@_getIdObj query).update(_.omit query, @idKeys)

  upsert: (query, options = {}) ->
    @logger.debug () -> "upsert(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    ids = @_getIdObj query
    entity = _.omit query, @idKeys
    @logger.debug () -> "ids: #{JSON.stringify(ids)}"
    @logger.debug () -> "entity: #{JSON.stringify(entity)}"

    upsertQueryString = ServiceCrud.getUpsertQueryString ids, entity, @dbFn.tableName
    @_wrapTransaction options.transaction ? @dbFn().raw upsertQueryString

  delete: (query, options = {}) ->
    @logger.debug () -> "delete(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapTransaction options.transaction ? @dbFn().where(query).delete()

module.exports = ServiceCrud
