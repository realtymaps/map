_ = require 'lodash'
tables = require '../../backend/config/tables'
sinon = require 'sinon'
_logger = require("./logger").spawn('SqlMock')
Promise = require 'bluebird'
dbs = require '../../backend/config/dbs'

_sqlFns = [
  'select'
  'groupBy'
  'where'
  'orWhere'
  'whereIn'
  'insert'
  'update'
  'del'
  'delete'
  'innerJoin'
  'leftJoin'
  'count'
  'raw'
  'groupByRaw'
  'whereRaw'

  'as'
  'from'
  'orderBy'
]

class SqlMock
  ### Helper class for shielding database from sql queries during tests.  Advantages include:
    1) database operators will not act on database, to avoid inadvertently insert/update/delete
       on data during complex query tests
    2) simplified handlers for assessing operator calls (via sinon api)
    3) simplified assessment of flow through '.then' query callback evaluators, no matter
       how many are chained, and easily test input/output of callbacks

  ###

  constructor: (@groupName, @tableHandle, @options = {}) ->
    @logger = _logger.spawn("#{@groupName}:#{@tableHandle}")
    if @options.debugNS
      @logger = @logger.spawn(@options.debugNS)

    @setResult(@options.result ? undefined) unless @options.results
    @setResults(@options.results ? undefined) unless @options.result
    @error = @options.error ? undefined
    @_svc = @options.dbFn ? undefined

    if @options.dbFn?
      @_svc = @options.dbFn
      @logger.debug () -> "dbFn set: #{@_svc.tableName}"

    # dynamic instance hooks for the mock sql calls
    @[@groupName] = @
    @[@tableHandle] = (trx) =>
      if trx?
        @commitSpy = sinon.spy(trx, 'commit')
        @rollbackSpy = sinon.spy(trx, 'rollback')
      return @
    @tableName = @tableHandle

    @returningsSpy = sinon.spy()

    _sqlFns.forEach (name) =>
      # spy on query-operators
      @[name + 'Spy'] = sinon.spy()

    @init()

  @dbs:
    get: (main) ->
      temptrx =
        commit: ->
        rollback: ->
      transaction: (callback) ->
        callback(temptrx)

  dbFn: () =>
    fn = () =>
      @logger.debug "dbFn invoked"
      @
    fn.tableName = @tableName
    @logger.debug () -> "tablename: #{@tableName}"
    fn

  setResult: (result) ->
    @setResults [result]

  setResults: (results = []) ->
    @logger.debug () -> "setting results #{JSON.stringify(results)}"
    if !_.isArray results
      throw new Error "Results must be of type Array."
    @results = results.reverse() #be like a queue

  getResult: ->
    if @results.length
      ret = @results.pop()
      @logger.debug () -> "sending result, leaving #{@results.length} results in queue"
      return ret

  setError: (error) ->
    @error = error

  init: () ->
    @initSvc()
    @initMaintenanceContainers()

  initMaintenanceContainers: () ->
    @_queryChainFlag = false
    @_queryArgChain = []

  initSvc: () ->
    if @groupName == 'dbs' and @tableHandle == 'main' # special case svc
      @logger.debug "hooking dbs.get('main') for service"
      @_svc = dbs.get('main')
    else
      @logger.debug () -> "hooking tables.#{@groupName}.#{@tableHandle} for service"
      @_svc ?= tables[@groupName][@tableHandle]
      @tableName = @_svc.tableName or @tableHandle
      @_svc = @_svc()
    @_svc

  resetSpies: () ->
    _sqlFns.forEach (name) =>
      @[name + 'Spy'].reset()

  _appendArgChain: (operator, args) ->
    @_queryArgChain.push
      operator: operator
      args: args

  _appendThenChain: (callback) ->
    @thenCallbacks.push callback

  _appendCatchChain: (err) ->
    @catchCallbacks.push err

  _quickQuery: () ->
    if !@_queryChainFlag
      for link in @_queryArgChain
        if _.isFunction @_svc[link.operator]
          @_svc = @_svc[link.operator](link.args...)
      @_queryChainFlag = true
    @_svc

  #### public evaluators ####
  then: (handler) ->
    if @error?
      return Promise.reject(@error)
    @logger.debug () -> "resolving tables.#{@groupName}.#{@tableHandle} with #{@result}"
    Promise.resolve(@getResult()).then handler

  catch: (predicate, handler) ->
    if @error?

      if !handler?
        handler = predicate
        predicate = undefined

      @logger.debug.cyan () -> "rejecting tables.#{@groupName}.#{@tableHandle} with #{@error}"

      if predicate?
        return Promise.reject(@error).catch predicate, handler
      else
        return Promise.reject(@error).catch handler

    @logger.debug () -> "resolving UNCAUGHT error tables.#{@groupName}.#{@tableHandle} with #{@result}"
    return Promise.resolve(@getResult())

  toString: () ->
    @_quickQuery().toString()

  toSQL: () ->
    @_quickQuery().toSQL()

  returning: () ->
    @returningsSpy(arguments...)
    @

SqlMock.sqlMock = () ->
  new SqlMock arguments...

_sqlFns.forEach (name) ->
  SqlMock::[name] = ->
    @logger.debug () -> "called #{@tableHandle} #{name}"

    @[name + 'Spy'](arguments...)
    @logger.debug () -> "called #{@tableHandle} #{name}Spy"

    @_appendArgChain(name, arguments)
    @logger.debug () -> "appended #{@tableHandle} #{name} to chain"
    @

module.exports = SqlMock
