{basePath} = require '../../globalSetup'
SqlMock = require '../../../specUtils/sqlMock'
ServiceCrud = require "#{basePath}/utils/crud/util.ezcrud.service.helpers"
{expect} = require 'chai'
require('chai').should()

describe 'util.ezcrud.service.helpers', ->

  describe 'ServiceCrud', ->
    beforeEach ->
      @sqlMock = new SqlMock 'config', 'dataSourceFields'
      dbFn = () =>
        @sqlMock
      dbFn.tableName = 'data_source_fields'

      @serviceCrud = new ServiceCrud(dbFn, {debugNS:'ezcrud:service'})
      @query =
        id: 1
        lorem: "ipsum's"

    it 'passes sanity check', ->
      ServiceCrud.should.be.ok
      @serviceCrud.should.be.ok

    it 'fails instantiation without dbFn', ->
      (-> new ServiceCrud()).should.throw()

    it 'gets id obj', ->
      idObj = @serviceCrud._getIdObj(@query)
      expect(idObj).to.deep.equal {'id':1}

    it 'scrutinizes id keys', ->
      expect(@serviceCrud._hasIdKeys(@query)).to.be.true
      expect(@serviceCrud._hasIdKeys({})).to.be.false

    it 'returns sqlQuery (knex) object', ->
      sqlQuery = @serviceCrud.exposeKnex().getAll(@query).knex
      expect(sqlQuery).to.deep.equal @sqlMock

    it 'passes getAll', () ->
      @serviceCrud.getAll(@query).then () =>
        @sqlMock.whereSpy.calledOnce.should.be.true

    it 'passes create', () ->
      @serviceCrud.create(@query).then () =>
        @sqlMock.insertSpy.calledOnce.should.be.true

    it 'passes getById', () ->
      @serviceCrud.getById(@query).then () =>
        @sqlMock.whereSpy.calledOnce.should.be.true

    it 'passes update', () ->
      @serviceCrud.update(@query).then () =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        @sqlMock.updateSpy.calledOnce.should.be.true

    it 'passes upsert', () ->
      @serviceCrud.upsert(@query).then () =>
        @sqlMock.rawSpy.calledOnce.should.be.true

    it 'passes delete', () ->
      @serviceCrud.delete(@query).then () =>
        @sqlMock.whereSpy.calledOnce.should.be.true
        @sqlMock.deleteSpy.calledOnce.should.be.true

    describe '_wrapQuery', () ->
      it 'returns knex obj', () ->
        @serviceCrud.create(@query, returnKnex:true)
        .knex.should.be.ok
