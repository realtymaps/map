_ = require 'lodash'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.dataSource.coffee'
tables = require '../../../backend/config/tables'
SqlMock = require '../../specUtils/sqlMock'
{expect, assert} = require 'chai'
require('chai').should()

describe 'service.dataSource.coffee', ->
  describe 'basic CRUD', ->
    beforeEach ->
      @config_dataSourceFields = new SqlMock 'config', 'dataSourceFields'
      @config_dataSourceLookups = new SqlMock 'config', 'dataSourceLookups'

      @tables =
        config:
          dataSourceFields: () =>
            @config_dataSourceFields
          dataSourceLookups: () =>
            @config_dataSourceLookups

      # rewire modules used directly inside service logic
      svc.__set__('tables', @tables)

      # aquire service class to be tested
      DataSourceServiceClass = svc.__get__('DataSourceService')

      # create service instance to test on
      dataSourceTest = new DataSourceServiceClass @config_dataSourceFields.dbFn(), "MetadataEntryID"

      # reset module to this test instance
      @dataSourceSvc = dataSourceTest

    it 'should GET all data source fields', (done) ->
      @dataSourceSvc.getAll().then () =>
        expect(@config_dataSourceFields.toString()).to.contain('select * from "config_data_source_fields"')
        expect(@config_dataSourceFields.selectSpy.calledOnce).to.be.false # no select is explicitly called in Crud class
        expect(@config_dataSourceFields.whereSpy.calledOnce).to.be.true # we always do where() though
        done()


  describe 'getColumnList', ->
    beforeEach ->
      @dsSqlMock = new SqlMock 'config', 'dataSourceFields',
        result: [
          MetadataEntryID: 1
          LongName: 'a.long.name'
          SystemName: 'A Long Name'
        ,
          MetadataEntryID: 2
          LongName: 'another.long.name'
          SystemName: 'Another Long Name'
        ]

      svc.__set__('tables', @dsSqlMock)

      @query =
        data_source_id: 'blackknight'
        data_source_type: 'county'
        data_list_type: 'tax'


    it 'should GET columns', (done) ->
      svc.getColumnList(@query.data_source_id, @query.data_list_type).then (queryResults) =>
        expect(@dsSqlMock.toString()).to.contain('"data_source_id" = \'blackknight\'')
        expect(@dsSqlMock.toString()).to.contain('"data_list_type" = \'tax\'')
        expect(@dsSqlMock.selectSpy.calledOnce).to.be.true
        expect(@dsSqlMock.whereSpy.calledOnce).to.be.true
        expect(queryResults[0]).to.have.property 'LongName'
        expect(queryResults[1]).to.have.property 'LongName'
        done()


  describe 'getLookupTypes', ->
    beforeEach ->
      @dsSqlMock = new SqlMock 'config', 'dataSourceLookups'
      svc.__set__('tables', @dsSqlMock)

      @query =
        data_source_id: 'blackknight'
        data_list_type: 'deed'
        lookup_id: 'AIR_CONDITIONING_TYPE'

    it 'should GET lookup fields', (done) ->
      svc.getLookupTypes(@query.data_source_id, @query.data_list_type, @query.lookup_id).then () =>
        expect(@dsSqlMock.toString()).to.contain('"data_source_id" = \'blackknight\'')
        expect(@dsSqlMock.toString()).to.contain('"data_list_type" = \'deed\'')
        expect(@dsSqlMock.toString()).to.contain('"LookupName" = \'AIR_CONDITIONING_TYPE\'')
        @dsSqlMock.selectSpy.calledOnce.should.be.true
        @dsSqlMock.whereSpy.calledOnce.should.be.true
        done()
