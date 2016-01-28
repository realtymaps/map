util = require 'util'
logger = require('../../config/logger').spawn('backend:ezcrud:service')
BaseObject = require '../../../common/utils/util.baseObject'
isUnhandled = require('../errors/util.error.partiallyHandledError').isUnhandled
ServiceCrudError = require('../errors/util.errors.crud').ServiceCrudError
_ = require 'lodash'
factory = require '../util.factory'


class ServiceCrud extends BaseObject
  constructor: (@dbFn, options = {}) ->
    @debug = () ->
    if options.debugNS and _.isString options.debugNS
      @debugLogger = logger.spawn options.debugNS
      @debug = (msg) => @debugLogger.debug msg

    # reteurnKnex flag activates the CRUD handlers below to return a {knex: <transaction>} object
    @returnKnex = options.returnKnex ? false
    # idKeys format here helps multi-pk support
    @idKeys = options.idKeys ? ['id']
    @idKeys = [@idKeys] unless _.isArray @idKeys
    unless _.isFunction @dbFn
      throw new ServiceCrudError('dbFn must be a knex function')
    @debug "Crud service instance made with options: #{util.inspect(options, false, 0)}"

  # Static function that produces an upsert query string given ids and entity of model.
  # This exposes upsert query string for any other modules to use if desired and only
  # requires ids and entity as objects (idobj helps for support on multi-id pks)
  @getUpsertQueryString: (idObj, entityObj, tableName) ->
    # "pre-process" data, stringify any JSON data
    for k,v of entityObj
      entity[k] = JSON.stringify(v) if _.isObject v

    # some string processing to help give us good query values:
    #   util.inspect gives good array repr of entity values that can be used for sql values
    #   substring out non-JSON field brackets (to avoid risk removing brackets from json arrays)
    idKeys = "#{_.keys(idObj)}"
    entityKeys = "#{_.keys(entityObj)}"
    allKeys = "#{idKeys},#{entityKeys}"

    idValues = "#{util.inspect(_.values(idObj))}"
    idValues = idValues.substring(1,idValues.length-1)
    entityValues = "#{util.inspect(_.values(entityObj))}"
    entityValues = entityValues.substring(1,entityValues.length-1)
    allValues = "#{idValues},#{entityValues}"

    # postgresql template for raw query
    # (no real native knex support yet: https://github.com/tgriesser/knex/issues/1121)
    qstr = """
     INSERT INTO
       #{tableName}
       (#{allKeys}) 
     VALUES
       (#{allValues}) 
     ON CONFLICT
       (#{idKeys}) 
     DO UPDATE SET
       (#{entityKeys}) = (#{entityValues}) 
    """

    # "post-process" data, sanitize the resulting string above suitable as raw query
    qstr = qstr.replace(/\n/g,'')
    qstr

  # helpers for query / id mgmt
  _getIdObj: (sourceObj) ->
    keys = _.merge(_.zipObject(@idKeys), _.pick(sourceObj, @idKeys))
    @debug "_getIdObj(), keys=#{JSON.stringify(keys)}"
    keys

  _hasIdKeys: (testObj) ->
    @debug "_hasIdKeys:"
    @debug "idKeys=#{@idKeys}"
    @debug "testObj=#{testObj}"
    _.every @idKeys, _.partial(_.has, testObj)

  # In order to leverage centralized transaction handling (error catching etc) transactions
  #   should be routed through this helper method.
  # As things may grow on this class, this can hold any shared, central logic pertinent to the 'custom' scheme
  #   that we develop in the future
  custom: (transaction) ->
    @debug "Using custom transaction"
    @_wrapTransaction transaction

  # intermediate function to flag _wrapTransaction to return unevaluated knex
  exposeKnex: () ->
    @returnKnexTempFlag = true
    @debug "Flagged to return knex object, use `.knex` handle of returned object"
    @

  # centralized handling, such as catching errors, for all queries including custom ones
  _wrapTransaction: (transaction) ->
    @debug transaction.toString()

    # return an objectified handle to knex obj if flagged
    if @returnKnex or @returnKnexTempFlag
      @returnKnexTempFlag = false
      return {knex: transaction} # exposes unevaluated knex

    # evaluate
    transaction.then (result) =>
      result
    .catch isUnhandled, (error) =>
      @debug error
      throw new ServiceCrudError(error, "Error evaluating query: #{transaction}")

  getAll: (query = {}, options = {}) ->
    @debug "getAll(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapTransaction options.transaction ? @dbFn().where(query)

  create: (query, options = {}) ->
    @debug "create(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapTransaction options.transaction ? @dbFn().insert(query)

  # implies restrictions and forces on id matches
  getById: (query, options = {}) =>
    # allow `query` to represent a single, simple num/str id
    query = {"#{@idKeys[0]}": query} unless _.isObject query or @idkeys.length > 1
    @debug "getById(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    throw new ServiceCrudError("getById on #{@dbFn.tableName}: required id fields `#{@idkeys}` missing") unless @_hasIdKeys query
    @_wrapTransaction options.transaction ? @dbFn().where @_getIdObj query

  update: (query, options = {}) ->
    @debug "update(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    throw new ServiceCrudError("update on #{@dbFn.tableName}: required id fields `#{@idkeys}` missing") unless @_hasIdKeys query
    ids = @_getIdObj query
    entity = _.omit query, @idKeys
    @debug "ids: #{JSON.stringify(ids)}"
    @debug "entity: #{JSON.stringify(entity)}"
    @_wrapTransaction options.transaction ? @dbFn().where(@_getIdObj query).update(_.omit query, @idKeys)

  upsert: (query, options = {}) ->
    @debug "upsert(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    throw new ServiceCrudError("upsert on #{@dbFn.tableName}: required id fields `#{@idkeys}` missing") unless @_hasIdKeys query
    ids = @_getIdObj query
    entity = _.omit query, @idKeys
    @debug "ids: #{JSON.stringify(ids)}"
    @debug "entity: #{JSON.stringify(entity)}"

    upsertQueryString = ServiceCrud.getUpsertQueryString ids, entity, @dbFn.tableName
    @_wrapTransaction options.transaction ? @dbFn().raw upsertQueryString

  delete: (query, options = {}) ->
    @debug "delete(), query=#{util.inspect(query,false,0)}, options=#{util.inspect(options,false,0)}"
    @_wrapTransaction options.transaction ? @dbFn().where(query).delete()

module.exports = ServiceCrud
