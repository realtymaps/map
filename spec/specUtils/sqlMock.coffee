_ = require 'lodash'
tables = require '../../backend/config/tables'
sinon = require 'sinon'

class SqlMock
  ### Helper class for shielding database from sql queries during tests.  Advantages include:
    1) database operators will not act on database, to avoid inadvertently insert/update/delete
       on data during complex query tests
    2) simplified handlers for assessing operator calls (via sinon api)
    3) simplified assessment of flow through '.then' query callback evaluators, no matter
       how many are chained, and easily test input/output of callbacks

  ###
  constructor: (@options) ->
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

    # spy on query-operators
    @selectSpy = sinon.spy()
    @groupBySpy = sinon.spy()
    @whereSpy = sinon.spy()
    @insertSpy = sinon.spy()
    @updateSpy = sinon.spy()
    @deleteSpy = sinon.spy()

    @init()

  @dbs:
    get: (main) ->
      temptrx =
        commit: ->
        rollback: ->
      transaction: (callback) ->
        callback(temptrx)

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
    @_svc = tables[@options.groupName][@options.tableHandle]

    # bootstrap
    @_svc = @_svc() # bootstrap

  getSvc: () ->
    @_svc

  resetSpies: () ->
    @selectSpy.reset()
    @groupBySpy.reset()
    @whereSpy.reset()
    @insertSpy.reset()
    @updateSpy.reset()
    @deleteSpy.reset()

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
        @_svc = @_svc[link.operator](link.args)
      @_queryChainFlag = true
    @_svc

  #### public operators ####
  select: (query) ->
    @selectSpy(query)
    @_appendArgChain('select', query)
    @

  groupBy: (cols) ->
    @groupBySpy(cols)
    @_appendArgChain('groupBy', cols)
    @

  where: (query) ->
    @whereSpy(query)
    @_appendArgChain('where', query)
    @

  insert: (args) ->
    @insertSpy(args)
    @_appendArgChain('insert', args)
    @

  update: (args) ->
    @updateSpy(args)
    @_appendArgChain('update', args)
    @

  delete: (args) ->
    @deleteSpy(args)
    @_appendArgChain('delete', args)
    @

  #### public evaluators ####
  then: (callback) ->
    @

  catch: (err) ->
    @

  toString: () ->
    @_quickQuery().toString()

  toSQL: () ->
    @_quickQuery().toSQL()


module.exports =
  SqlMock: SqlMock
