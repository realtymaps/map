subject = require '../../../../backend/services/bookshelfext/bookshelf.raw'
app = do require 'express'
Promise = require 'bluebird'

describe 'bookshelf.raw', ->
  beforeEach ->
    @sqlResult = ''
    @db =
      knex:
        raw: (sql) =>
          console.info "WHAT THE FUCK! %j",
          @sqlResult = sql
          Promise.resolve()

    #this works great below
    @dbWError =
      knex:
        raw: (sql) =>
          throw new Error "mock error"
          @sqlResult = sql

    # next = sinon.spy()

  it 'exists', ->
    subject.should.be.ok


  it 'calls knex.raw without error', (done) ->
    testSql = 'testSql1'

    promise = subject @db, testSql, 'testFn'

    console.info "promise: %j", promise
    promise.then =>
      console.info "WHY IN THE HELL IS THIS NEVER BEING HIT!!!!!!???"
      @sqlResult.should.be.eql testSql
      done()

  it 'calls knex.raw with error', (done)->
    testSql = 'testSql2'
    error = false
    subject @dbWError, testSql, 'testFn'
    .catch (e) =>
      error = true
      @sqlResult.should.not.be.eql testSql
    .then ->
      error.should.be.ok
      done()
