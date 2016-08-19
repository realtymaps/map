_ = require 'lodash'
tables = require '../../backend/config/tables'
dbs = require '../../backend/config/dbs'
sinon = require 'sinon'
_logger = require("./logger").spawn('SqlMock')
Promise = require 'bluebird'
dbs = require '../../backend/config/dbs'

_sqlFns = ['raw'].concat require 'knex/lib/query/methods'

class SqlMock
  ### Helper class for shielding database from sql queries during tests.  Advantages include:
    1) database operators will not act on database, to avoid inadvertently insert/update/delete
       on data during complex query tests
    2) simplified handlers for assessing operator calls (via sinon api)
    3) simplified assessment of flow through '.then' query callback evaluators, no matter
       how many are chained, and easily test input/output of callbacks
  ###

  ### Options
    blockToString: Any time a raw() value is passed to a knex function such as where(), update(), etc,
      subsequently calling toString() will break because raw() will return a spy instead of a string. In
      some cases service methods call toString() themselves. Setting the blockToString option prevents
      toString() from actually being called.
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
      @logger.debug () => "dbFn set: #{@_svc.tableName}"

    # dynamic instance hooks for the mock sql calls
    @[@groupName] = @
    @[@tableHandle] = (opts={}) =>
      if opts.transaction?
        @commitSpy = sinon.spy(opts.transaction, 'commit')
        @rollbackSpy = sinon.spy(opts.transaction, 'rollback')
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
    @buildTableName = dbs.buildTableName(@tableName)

    fn = ({subid} = {}) =>
      if subid?
        @_svc = null
        @init({subid})
      @logger.debug "dbFn invoked"
      @
    fn.tableName = @tableName
    fn.buildTableName = @buildTableName
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
      @logger.debug () => "sending result, leaving #{@results?.length} results in queue"
      return ret

  setError: (error) ->
    @error = error

  init: ({subid} = {}) ->
    @initSvc({subid})
    @initMaintenanceContainers()

  initMaintenanceContainers: () ->
    @_queryChainFlag = false
    @_queryArgChain = []

  initSvc: ({subid} = {}) ->
    if @groupName == 'dbs' and @tableHandle == 'main' # special case svc
      @logger.debug "hooking dbs.get('main') for service"
      @_svc = dbs.get('main')
    else
      @logger.debug () => "hooking tables.#{@groupName}.#{@tableHandle} for service"
      @_svc ?= tables[@groupName][@tableHandle]
      @tableName = @_svc.tableName or @tableHandle
      if subid?
        @tableName = @buildTableName(subid)
      @_svc = @_svc({subid})
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

  # This method will eventually be removed once we remove reliance on testing SQL strings
  _quickQuery: () ->
    # @logger.debug @_svc
    # @logger.debug "_queryChainFlag is #{@_queryChainFlag}"
    if !@_queryChainFlag
      for link in @_queryArgChain
        # @logger.debug link
        # @logger.debug typeof link
        if _.isFunction(@_svc[link.operator]) && link.operator != 'raw'
          # @logger.debug 'updating @_svc'
          @_svc = @_svc[link.operator](link.args...)
      # @logger.debug "setting @_queryChainFlag true"
      @_queryChainFlag = true
    # @logger.debug @_svc
    @_svc

  #### public evaluators ####
  then: (handler) ->
    if @error?
      return Promise.reject(@error)
    result = @getResult()
    @logger.debug () => "resolving tables.#{@groupName}.#{@tableHandle} with #{result}"
    Promise.resolve(result).then handler

  catch: (predicate, handler) ->
    if @error?

      if !handler?
        handler = predicate
        predicate = undefined

      @logger.debug.cyan () => "rejecting tables.#{@groupName}.#{@tableHandle} with #{@error}"

      if predicate?
        return Promise.reject(@error).catch predicate, handler
      else
        return Promise.reject(@error).catch handler

    result = @getResult()
    @logger.debug () => "resolving UNCAUGHT error tables.#{@groupName}.#{@tableHandle} with #{JSON.stringify result}"
    return Promise.resolve(result)

  toString: () ->
    @logger.warn "COMPARING SQL STRINGS IS LIKELY TO BREAK!"
    if !@options.blockToString
      @_quickQuery().toString()
    else
      "blockToString was set, so this is fake SQL"

  toSQL: () ->
    @logger.warn "COMPARING SQL STRINGS IS LIKELY TO BREAK!"
    if !@options.blockToString
      @_quickQuery().toSQL()
    else
      "blockToString was set, so this is fake SQL"

  returning: () ->
    @returningsSpy(arguments...)
    @

SqlMock.sqlMock = () ->
  new SqlMock arguments...

_sqlFns.forEach (name) ->
  SqlMock::[name] = ->
    @logger.debug () => "called #{@tableHandle} #{name}"

    @[name + 'Spy'](arguments...)
    @logger.debug () => "called #{@tableHandle} #{name}Spy"

    @_appendArgChain(name, arguments)
    @logger.debug () => "appended #{@tableHandle} #{name} to chain"
    @

module.exports = SqlMock
