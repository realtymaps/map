_ = require 'lodash'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.dataSource.coffee'
tables = require '../../../backend/config/tables'
SqlMock = require '../../specUtils/sqlMock'
{expect, assert} = require 'chai'
require 'should'

describe 'service.dataSource.coffee', ->
  describe 'basic CRUD', ->
    beforeEach ->
      @dsSqlMock = new SqlMock
        groupName: 'config'
        tableHandle: 'dataSourceFields'

      svc.__get__('tables', @dsSqlMock)

      @query =
        data_source_id: 'blackknight'
        data_list_type: 'tax'

    it 'should GET all data source fields', (done) ->
      svc.getAll().then () =>
        expect(@dsSqlMock.toString()).to.contain('select * from "config_data_source_fields"')
        @dsSqlMock.selectSpy.calledOnce.should.be.true
        @dsSqlMock.whereSpy.called.should.be.false
        done()


  describe 'getColumnList', ->
    beforeEach ->
      @dsSqlMock = new SqlMock
        groupName: 'config'
        tableHandle: 'dataSourceFields'
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
      calledWithArgs = ["MetadataEntryID","SystemName","ShortName","LongName","DataType","Interpretation","LookupName"]
      svc.getColumnList(@query.data_source_id, @query.data_source_type, @query.data_list_type).then (queryResults) =>
        expect(@dsSqlMock.toString()).to.contain('"data_source_id" = \'blackknight\'')
        expect(@dsSqlMock.toString()).to.contain('"data_source_type" = \'county\'')
        expect(@dsSqlMock.toString()).to.contain('"data_list_type" = \'tax\'')
        expect(@dsSqlMock.selectSpy.calledOnce).to.be.true
        expect(@dsSqlMock.selectSpy.args).to.deep.equal [calledWithArgs]
        expect(@dsSqlMock.whereSpy.calledOnce).to.be.true
        expect(@dsSqlMock.whereSpy.args).to.deep.equal [[@query]]
        expect(queryResults[0]).to.have.property 'LongName'
          .and.equal 'alongname'
        expect(queryResults[1]).to.have.property 'LongName'
          .and.equal 'anotherlongname'
        done()


  describe 'getLookupTypes', ->
    beforeEach ->
      @dsSqlMock = new SqlMock
        groupName: 'config'
        tableHandle: 'dataSourceLookups'

      svc.__set__('tables', @dsSqlMock)

      @query =
        data_source_id: 'blackknight'
        lookup_id: 'AIR_CONDITIONING_TYPE'

    it 'should GET lookup fields', (done) ->
      svc.getLookupTypes(@query.data_source_id, @query.lookup_id).then () =>
        expect(@dsSqlMock.toString()).to.contain('"data_source_id" = \'blackknight\'')
        expect(@dsSqlMock.toString()).to.contain('"LookupName" = \'AIR_CONDITIONING_TYPE\'')
        @dsSqlMock.selectSpy.calledOnce.should.be.true
        @dsSqlMock.whereSpy.calledOnce.should.be.true
        done()
