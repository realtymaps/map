subject = require '../../../../backend/services/bookshelfext/bookshelf.raw'
Promise = require 'bluebird'
next = undefined

describe 'bookshelf.raw', ->
  beforeEach ->
    next = sinon.spy()

    @calledSql = ''
    @db =
      knex:
        raw: (sql) =>
          @calledSql = sql
          Promise.resolve(rows: toJSON: () -> return "{}")

    @dbWError =
      knex:
        raw: (sql) =>
          Promise.reject "mock error"

  it 'exists', ->
    subject.should.be.ok


  it 'calls knex.raw without error', (done) ->
    testSql = 'testSql1'

    promise = subject @db, testSql, next, 'testFn'

    console.info "promise: %j", promise
    promise.then (result) =>
      result.should.be.eql '{}'
      @calledSql.should.be.eql testSql
      done()

  it 'calls knex.raw with error', (done)->
    testSql = 'testSql2'
    error = false
    subject @dbWError, testSql, next, 'testFn'
    .catch (e) =>
      error = true
      @calledSql.should.not.be.eql testSql
    .then ->
      error.should.be.ok
      done()

  describe 'invalid args still returns a promise!', ->
      it 'db undefined', (done) ->
        subject().catch (msg) ->
          done()
          msg.should.be.eql 'db is not defined'

      it 'sql undefined', (done) ->
        subject({}).catch (msg) ->
          msg.should.be.eql 'sql is not defined'
          done()

      it 'next undefined', (done) ->
        subject(@db,"crap").then (row) ->
          row.should.be.eql '{}'
          done()
