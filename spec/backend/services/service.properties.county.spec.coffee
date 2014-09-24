subjectFn = require '../../../backend/services/service.properties.county'
Promise = require 'bluebird'
next = subject =testSql = undefined
testFnName  = testSafeQuerySql = ""

describe 'service.properties.county', ->
  beforeEach ->
    #reset
    next = subject =testSql = testFnName = testSafeQuerySql = undefined

    @safeQuery = (db, sql) ->
      testSafeQuerySql = sql
      Promise.resolve( rows: toJSON = -> '{}')

    @countySql =
      all: ->
        "all"

  it 'ctor exist', ->
    subjectFn.should.be.ok

  it 'exists', ->
    subjectFn().should.be.ok

  describe 'overriden dependencies', ->
    describe 'debug and safeQuery get the same sql', ->
