notesSvc = require('../../../backend/services/services.user').notes
Promise = require 'bluebird'
sqlHelpers = require '../../../backend/utils/util.sql.helpers'
{Crud} = require '../../../backend/utils/crud/util.crud.service.helpers'
notesCols = sqlHelpers.columns.notes
sinon = require 'sinon'

describe 'service.user.notes', ->
  beforeEach ->
    @instance = notesSvc

  describe 'notes', ->
    it 'exists', ->
      @instance.should.be.ok

    describe 'defaults', ->

      it 'ctor', ->
        @instance.dbFn.should.be.ok
      it 'getAll', ->
        @instance.getAll().toString().should.equal """select * from "#{@instance.dbFn.tableName}" """.trim()

      it 'getById', ->
        @instance.getById(1).toString()
        .should.equal """select * from "#{@instance.dbFn.tableName}" where "id" = 1"""

      #TODO Should this be flagged to fix?
      #this shows that count is returning more than most expected.. but it is not really being used.
      #an explicit dbFn for count might get better behavior, but is it worth it?
      it 'count', ->
        @instance.count(test:'test').toString()
        .should.equal """select count(*) from "#{@instance.dbFn.tableName}" where "test" = 'test'"""

      describe 'update', ->
        it 'no safe', ->
          @instance.update(1, {test:'test'}).toString()
          .should.equal """update "#{@instance.dbFn.tableName}" set "test" = 'test' where "id" = 1 returning "id" """.trim()

        it 'safe', ->
          @instance.update(1, {test:'test', crap: 2}, ['test']).toString()
          .should.equal """update "#{@instance.dbFn.tableName}" set "test" = 'test' where "id" = 1 returning "id" """.trim()

      describe 'create', ->
        it 'default', ->
          @instance.create({id:1, test:'test'}).toString()
          .should.equal """insert into "#{@instance.dbFn.tableName}" ("id", "test") values (1, 'test') returning "id" """.trim()
        it 'id', ->
          @instance.create({id:1, test:'test'}, 2).toString()
          .should.equal """insert into "#{@instance.dbFn.tableName}" ("id", "test") values (2, 'test') returning "id" """.trim()

      describe 'upsert', ->
        describe 'record exists', ->
          before ->
            sinon.stub(@instance, 'getAll').returns Promise.try () -> [1]
            sinon.stub(Crud::, 'update').returns Promise.try () -> [1]
            sinon.stub(Crud::, 'create').returns Promise.try () -> [1]

          after ->
            @instance.getAll.restore()
            Crud::update.restore()
            Crud::create.restore()

          it 'with update', ->
            obj = id: 1
            @instance.upsert obj, ['id']
            .then () ->
              Crud::update.called.should.be.true
              Crud::update.reset()

          it 'no update', ->
            obj = id: 1
            @instance.upsert obj, ['id'], false
            .then () ->
              Crud::update.called.should.be.false
              Crud::update.reset()

        describe 'record does not exist', ->
          before ->
            sinon.stub(@instance, 'getAll').returns Promise.try () -> []
            sinon.stub(Crud::, 'update').returns Promise.try () -> [1]
            sinon.stub(Crud::, 'create').returns Promise.try () -> [1]

          after ->
            @instance.getAll.restore()
            Crud::update.restore()
            Crud::create.restore()

          it 'new record', ->
            @instance.upsert id: 1, ['id']
            .then () ->
              Crud::create.called.should.be.true
              Crud::create.reset()

      it 'delete', ->
        @instance.delete(1).toString()
        .should.equal """delete from "#{@instance.dbFn.tableName}" where "id" = 1"""
