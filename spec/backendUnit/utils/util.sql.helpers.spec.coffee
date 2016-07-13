{basePath} = require '../globalSetup'
dbs = require("#{basePath}/config/dbs")
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
{expect, should} = require 'chai'
should()
SqlMock = require '../../specUtils/sqlMock'

describe 'util.sql.helpers', ->

  it 'returns correct upsert query string', ->
  # it's not SQL standard, but \' is acceptable to postgres: http://www.postgresql.org/docs/9.4/interactive/sql-syntax-lexical.html#SQL-SYNTAX-CONSTANTS
    expectedSql = """INSERT INTO "temp_table" ("id", "lorem") VALUES ('1', 'ipsum\\'s') ON CONFLICT ("id") DO UPDATE SET ("lorem") = ('ipsum\\'s') RETURNING "id" """
    ids =
      id: 1
    entity =
      lorem: "ipsum's"
    tableName = 'temp_table'
    query = sqlHelpers.buildUpsertBindings {idObj:ids, entityObj: entity, tableName}
    expect(dbs.connectionless.raw(query.sql, query.bindings).toString().trim()).to.equal expectedSql.trim()

  it 'returns correct upsert query string with null pk and null values', ->
    expectedSql = """INSERT INTO "temp_table" ("id", "lorem") VALUES (DEFAULT, NULL) ON CONFLICT ("id") DO UPDATE SET ("lorem") = (NULL) RETURNING "id" """
    ids =
      id: null
    entity =
      lorem: null
    tableName = 'temp_table'
    query = sqlHelpers.buildUpsertBindings {idObj:ids, entityObj: entity, tableName}
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
    query = sqlHelpers.buildUpsertBindings {idObj:ids, entityObj: entity, tableName}
    expect(dbs.connectionless.raw(query.sql, query.bindings).toString().trim()).to.equal expectedSql.trim()

  describe "whereIn", ->
    mock = query = null

    beforeEach ->
      mock = new SqlMock 'finalized', 'combined'
      query = mock.dbFn()()

    describe "non array", ->
      it "int", ->
        query = sqlHelpers.whereIn(query, 'rm_property_id', 1)
        mock.whereSpy.called.should.be.ok
        mock.whereSpy.args.should.be.eql [
          ["rm_property_id", 1]
        ]

      it "string", ->
        query = sqlHelpers.whereIn(query, 'rm_property_id', "12021_002_001")
        mock.whereSpy.called.should.be.ok
        mock.whereSpy.args.should.be.eql [
          ["rm_property_id", "12021_002_001"]
        ]

      it "boolean", ->
        query = sqlHelpers.whereIn(query, 'rm_property_id', true)
        mock.whereSpy.called.should.be.ok
        mock.whereSpy.args.should.be.eql [
          ["rm_property_id", true]
        ]

      it "undefined", ->
        query = sqlHelpers.whereIn(query, 'rm_property_id', undefined)
        mock.whereRawSpy.called.should.be.ok
        mock.whereRawSpy.args.should.be.eql [
          ["FALSE"]
        ]

      it "null", ->
        query = sqlHelpers.whereIn(query, 'rm_property_id', undefined)
        mock.whereRawSpy.called.should.be.ok
        mock.whereRawSpy.args.should.be.eql [
          ["FALSE"]
        ]

      describe 'array', ->
        describe "single item", ->
          it "int", ->
            query = sqlHelpers.whereIn(query, 'rm_property_id', [1])
            mock.whereSpy.called.should.be.ok
            mock.whereSpy.args.should.be.eql [
              ["rm_property_id", 1]
            ]

          it "string", ->
            query = sqlHelpers.whereIn(query, 'rm_property_id', ["12021_002_001"])
            mock.whereSpy.called.should.be.ok
            mock.whereSpy.args.should.be.eql [
              ["rm_property_id", "12021_002_001"]
            ]

          it "boolean", ->
            query = sqlHelpers.whereIn(query, 'rm_property_id', [true])
            mock.whereSpy.called.should.be.ok
            mock.whereSpy.args.should.be.eql [
              ["rm_property_id", true]
            ]

        describe "many items", ->
          it "int", ->
            query = sqlHelpers.whereIn(query, 'rm_property_id', [1,2,3])
            mock.whereInSpy.called.should.be.ok
            mock.whereInSpy.args.should.be.eql [
              ["rm_property_id", [1,2,3]]
            ]

          it "string", ->
            query = sqlHelpers.whereIn(query, 'rm_property_id', ["12021_002_001", "12021_002_002"])
            mock.whereInSpy.called.should.be.ok
            mock.whereInSpy.args.should.be.eql [
              ["rm_property_id", ["12021_002_001", "12021_002_002"]]
            ]

          it "boolean", ->
            query = sqlHelpers.whereIn(query, 'rm_property_id', [true,false])
            mock.whereInSpy.called.should.be.ok
            mock.whereInSpy.args.should.be.eql [
              ["rm_property_id", [true, false]]
            ]
