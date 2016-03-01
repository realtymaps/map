_ = require 'lodash'
{basePath} = require '../../globalSetup'
sinon = require 'sinon'
SqlMock = require '../../../specUtils/sqlMock'
ServiceCrud = require "#{basePath}/utils/crud/util.ezcrud.service.helpers"
{expect} = require 'chai'
require('chai').should()
dbs = require("#{basePath}/config/dbs")

describe 'util.ezcrud.service.helpers', ->

  describe 'ServiceCrud', ->
    beforeEach ->
      @sqlMock = new SqlMock 'config', 'dataSourceFields'
      dbFn = () =>
        @sqlMock

      @serviceCrud = new ServiceCrud(dbFn, {debugNS:'ezcrud:service'})
      @query =
        id: 1
        lorem: "ipsum's"

    it 'passes sanity check', ->
      ServiceCrud.should.be.ok
      @serviceCrud.should.be.ok

    it 'fails instantiation without dbFn', ->
      (-> new ServiceCrud()).should.throw()

    it 'returns correct upsert query string', ->
      # it's not SQL standard, but \' is acceptable to postgres: http://www.postgresql.org/docs/9.4/interactive/sql-syntax-lexical.html#SQL-SYNTAX-CONSTANTS
      expectedSql = """INSERT INTO "temp_table" ("id", "lorem") VALUES ('1', 'ipsum\\'s') ON CONFLICT ("id") DO UPDATE SET ("lorem") = ('ipsum\\'s') RETURNING "id" """
      ids =
        id: 1
      entity =
        lorem: "ipsum's"
      tableName = 'temp_table'
      query = ServiceCrud.getUpsertQueryString ids, entity, tableName
      expect(dbs.connectionless.raw(query.sql, query.bindings).toString().trim()).to.equal expectedSql.trim()

    it 'returns correct upsert query string with null pk and null values', ->
      expectedSql = """INSERT INTO "temp_table" ("id", "lorem") VALUES (DEFAULT, NULL) ON CONFLICT ("id") DO UPDATE SET ("lorem") = (NULL) RETURNING "id" """
      ids =
        id: null
      entity =
        lorem: null
      tableName = 'temp_table'
      query = ServiceCrud.getUpsertQueryString ids, entity, tableName
      expect(dbs.connectionless.raw(query.sql, query.bindings).toString().trim()).to.equal expectedSql.trim()

    it 'returns correct upsert query string with objects and json', ->
      expectedSql = """INSERT INTO "temp_table" ("id_one", "id_two", "lorem", "some_json", "an_array") VALUES (DEFAULT, DEFAULT, 'ipsum\\'s', '{\\"one\\":1,\\"two\\":[\\"spec\\'s\\",\\"array\\",\\"of\\",\\"strings\\"]}', '[1,2,3]') ON CONFLICT ("id_one", "id_two") DO UPDATE SET ("lorem", "some_json", "an_array") = ('ipsum\\'s', '{\\"one\\":1,\\"two\\":[\\"spec\\'s\\",\\"array\\",\\"of\\",\\"strings\\"]}', '[1,2,3]') RETURNING "id_one", "id_two" """.replace(/\n/g,'')

      ids =
        id_one: null
        id_two: null
      entity =
        lorem: "ipsum's"
        some_json: {'one': 1, 'two':["spec's", "array", "of", "strings"]}
        an_array: [1, 2, 3]
      tableName = 'temp_table'
      query = ServiceCrud.getUpsertQueryString ids, entity, tableName
      expect(dbs.connectionless.raw(query.sql, query.bindings).toString().trim()).to.equal expectedSql.trim()

    it 'gets id obj', ->
      idObj = @serviceCrud._getIdObj(@query)
      expect(idObj).to.deep.equal {'id':1}

    it 'scrutinizes id keys', ->
      expect(@serviceCrud._hasIdKeys(@query)).to.be.true
      expect(@serviceCrud._hasIdKeys({})).to.be.false

    it 'returns sqlQuery (knex) object', ->
      sqlQuery = @serviceCrud.exposeKnex().getAll(@query).knex
      expect(sqlQuery).to.deep.equal @sqlMock

    it 'passes getAll', (done) ->
      @serviceCrud.getAll(@query).then (result) =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        done()

    it 'passes create', (done) ->
      @serviceCrud.create(@query).then (result) =>
        @sqlMock.insertSpy.calledOnce.should.be.true
        done()

    it 'passes getById', (done) ->
      @serviceCrud.getById(@query).then (result) =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        done()

    it 'passes update', (done) ->
      @serviceCrud.update(@query).then (result) =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        @sqlMock.updateSpy.calledOnce.should.be.true
        done()

    it 'passes upsert', (done) ->
      @serviceCrud.upsert(@query).then (result) =>
        @sqlMock.rawSpy.calledOnce.should.be.true
        done()

    it 'passes delete', (done) ->
      @serviceCrud.delete(@query).then (result) =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        @sqlMock.deleteSpy.calledOnce.should.be.true
        done()
