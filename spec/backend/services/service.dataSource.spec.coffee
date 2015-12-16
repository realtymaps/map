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
      svc.getAll()
      expect(@dsSqlMock.toString()).to.contain('select * from "config_data_source_fields"')
      @dsSqlMock.selectSpy.calledOnce.should.be.true
      @dsSqlMock.whereSpy.called.should.be.false
      done()


  describe 'getColumnList', ->
    beforeEach ->
      @dsSqlMock = new SqlMock
        groupName: 'config'
        tableHandle: 'dataSourceFields'

      svc.__set__('tables', @dsSqlMock)

      @query =
        data_source_id: 'blackknight'
        data_source_type: 'county'
        data_list_type: 'tax'

      @thenTestArg = [
        MetadataEntryID: 1
        LongName: 'a long name'
        SystemName: 'A Long Name'
      ,
        MetadataEntryID: 2
        LongName: 'another long name'
        SystemName: 'Another Long Name'
      ]

    it 'should GET columns', (done) ->
      svc.getColumnList(@query.data_source_id, @query.data_source_type, @query.data_list_type)
      expect(@dsSqlMock.toString()).to.contain('"data_source_id" = \'blackknight\'')
      expect(@dsSqlMock.toString()).to.contain('"data_source_type" = \'county\'')
      expect(@dsSqlMock.toString()).to.contain('"data_list_type" = \'tax\'')
      @dsSqlMock.selectSpy.calledOnce.should.be.true
      @dsSqlMock.whereSpy.calledOnce.should.be.true
      @dsSqlMock.orderBySpy.calledOnce.should.be.true
      @dsSqlMock.thenSpy().callCount.should.equal 1
      @dsSqlMock.catchSpy().callCount.should.equal 1

      fn = @dsSqlMock.getThenCallback(0)
      output = fn(@thenTestArg)
      expect(output[0]).to.have.property 'LongName'
        .and.equal 'a long name'
      expect(output[1]).to.have.property 'LongName'
        .and.equal 'another long name'

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
      svc.getLookupTypes(@query.data_source_id, @query.lookup_id)
      expect(@dsSqlMock.toString()).to.contain('"data_source_id" = \'blackknight\'')
      expect(@dsSqlMock.toString()).to.contain('"LookupName" = \'AIR_CONDITIONING_TYPE\'')
      @dsSqlMock.selectSpy.calledOnce.should.be.true
      @dsSqlMock.whereSpy.calledOnce.should.be.true
      @dsSqlMock.thenSpy().callCount.should.equal 1
      @dsSqlMock.catchSpy().callCount.should.equal 1

      done()
