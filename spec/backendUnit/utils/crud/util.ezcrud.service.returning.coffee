{basePath} = require '../../globalSetup'
sinon = require 'sinon'
SqlMock = require '../../../specUtils/sqlMock'
ReturningServiceCrud = require "#{basePath}/utils/crud/util.ezcrud.service.returning"
{expect} = require 'chai'
require('chai').should()


describe 'util.ezcrud.service.returning', ->

  describe 'ReturningServiceCrud', ->
    beforeEach ->
      @sqlMock = new SqlMock 'config', 'dataSourceFields'
      dbFn = () =>
        @sqlMock

      @instance = new ReturningServiceCrud(dbFn, {debugNS:'ezcrud:service'})
      @query =
        id: 1
        lorem: "ipsum's"

    it 'passes sanity check', ->
      ReturningServiceCrud.should.be.ok
      @instance.should.be.ok

    it 'fails instantiation without dbFn', ->
      (-> new ServiceCrud()).should.throw()

    it 'gets id obj', ->
      idObj = @instance._getIdObj(@query)
      expect(idObj).to.deep.equal {'id':1}

    it 'scrutinizes id keys', ->
      expect(@instance._hasIdKeys(@query)).to.be.true
      expect(@instance._hasIdKeys({})).to.be.false

    it 'returns sqlQuery (knex) object', ->
      sqlQuery = @instance.exposeKnex().getAll(@query).knex
      expect(sqlQuery).to.deep.equal @sqlMock

    it 'passes getAll', (done) ->
      @instance.getAll(@query).then (result) =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        done()

    it 'passes create', (done) ->
      @instance.create(@query).then (result) =>
        @sqlMock.insertSpy.calledOnce.should.be.true
        @sqlMock.returningSpy.calledOnce.should.be.true
        done()

    it 'passes getById', (done) ->
      @instance.getById(@query).then (result) =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        done()

    it 'passes update', (done) ->
      @instance.update(@query).then (result) =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        @sqlMock.updateSpy.calledOnce.should.be.true
        done()

    it 'passes upsert', (done) ->
      @instance.upsert(@query).then (result) =>
        @sqlMock.rawSpy.calledOnce.should.be.true
        done()

    it 'passes delete', (done) ->
      @instance.delete(@query).then (result) =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        @sqlMock.deleteSpy.calledOnce.should.be.true
        done()
