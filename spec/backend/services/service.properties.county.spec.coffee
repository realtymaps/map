subjectFn = require '../../../backend/services/service.properties.county'
Promise = require 'bluebird'
next = subject =testSql = testFnName = testSafeQuerySql = undefined

describe 'service.properties.county', ->
  beforeEach ->
    #reset
    next = subject =testSql = testFnName = testSafeQuerySql = undefined

    @debug = (fnName, sql) ->
      console.info "fnName: " + fnName
      testFnName = fnName
      testSql = sql

    @safeQuery = (db, sql) ->
      testSafeQuerySql = sql
      Promise.resolve( rows: toJSON = -> '{}')

    @countySql =
      all: ->
        "all"
      allByAddressNumbers: ->
        "allByAddressNumbers"
      allByApn: ->
        "allByApn"

  it 'ctor exist', ->
    subjectFn.should.be.ok

  it 'exists', ->
    subjectFn().should.be.ok

  describe 'overriden dependencies', ->
    describe 'debug and safeQuery get the same sql', ->
      it 'getAll', ->
        subjectFn(next, {},@safeQuery,@countySql,@debug,{}).getAll({})
        testSql.should.be.eql "all"
        testSafeQuerySql.should.be.eql testSql
        testFnName.should.be.eql "getAll"

      it 'getAddresses', ->
        subjectFn(next, {},@safeQuery,@countySql,@debug,{}).getAddresses({})
        testSql.should.be.eql "allByAddressNumbers"
        testSafeQuerySql.should.be.eql testSql
        testFnName.should.be.eql "getAddresses"

      it 'getByApn', ->
        subjectFn(next, {},@safeQuery,@countySql,@debug,{}).getByApn({})
        testSql.should.be.eql "allByApn"
        testSafeQuerySql.should.be.eql testSql
        testFnName.should.be.eql "getByApn"
