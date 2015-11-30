_ = require 'lodash'
tables = require '../../backend/config/tables'
sinon = require 'sinon'
colorWrap = require 'color-wrap'
colorWrap(console)
Promise = require 'bluebird'

_sqlFns = [
  'select'
  'groupBy'
  'where'
  'whereIn'
  'insert'
  'update'
  'delete'
  'innerJoin'
  'count'
]

class SqlMock
  ### Helper class for shielding database from sql queries during tests.  Advantages include:
    1) database operators will not act on database, to avoid inadvertently insert/update/delete
       on data during complex query tests
    2) simplified handlers for assessing operator calls (via sinon api)
    3) simplified assessment of flow through '.then' query callback evaluators, no matter
       how many are chained, and easily test input/output of callbacks

  ###
  constructor: (optionsOrDbFn) ->
    if _.isFunction optionsOrDbFn
      @_svc = optionsOrDbFn
    else
      @options = optionsOrDbFn
      if !@options.groupName?
        throw new Error('\'groupName\' is a required option for SqlMock class')
      if !@options.tableHandle?
        throw new Error('\'tableHandle\' is a required option for SqlMock class')

      # dynamic instance hooks for the mock sql calls
      @[@options.groupName] = @
      @[@options.tableHandle] = (trx) =>
        if trx?
          @commitSpy = sinon.spy(trx, 'commit')
          @rollbackSpy = sinon.spy(trx, 'rollback')
        return @

    # spy on query-evaluators
    @_thenSpy = sinon.spy(@, 'then')
    @_catchSpy = sinon.spy(@, 'catch')

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
      @
    fn.tableName = @tableName
    fn

  thenSpy: ->
    @_thenSpy

  getThenCallback: (idx) ->
    @_thenSpy.getCall(idx).args[0]

  catchSpy: ->
    @_catchSpy

  getCatchCallback: (idx) ->
    @_catchSpy.getCall(idx).args[0]

  init: () ->
    @initSvc()
    @initMaintenanceContainers()

  initMaintenanceContainers: () ->
    @_queryChainFlag = false
    @_queryArgChain = []

  initSvc: () ->
    @_svc = tables[@options.groupName][@options.tableHandle] unless @_svc
    @tableName = @options?.tableHandle or @_svc.tableName
    # console.log.cyan @tableName
    # bootstrap
    @_svc = @_svc() # bootstrap
    # console.log.cyan @_svc, true
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
        @_svc = @_svc[link.operator](link.args...)
      @_queryChainFlag = true
    @_svc

  #### public evaluators ####
  then: () ->
    #map toString to some result
    @

  catch: (err) ->
    @

  toString: () ->
    @_quickQuery().toString()

  toSQL: () ->
    @_quickQuery().toSQL()


SqlMock.sqlMock = () ->
  new SqlMock arguments...

_sqlFns.forEach (name) ->
  SqlMock::[name] = ->
    @[name + 'Spy'](arguments...)
    @_appendArgChain(name, arguments)
    @

module.exports = SqlMock
