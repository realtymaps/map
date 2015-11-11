_ = require 'lodash'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.dataSourceRules.coffee'
{PartiallyHandledError, isUnhandled} = require '../../../backend/utils/errors/util.error.partiallyHandledError'
tables = require '../../../backend/config/tables'
sqlMockUtil = require '../../specUtils/sqlMock.coffee'


describe 'service.dataSourceRules.coffee', ->
  describe 'private api', ->
    beforeEach ->
      @rulesTableSqlMock = new sqlMockUtil.SqlMock
        groupName: 'config'
        tableHandle: 'dataNormalization'

      svc.__set__('tables', @rulesTableSqlMock)
      @_addRulesFn = svc.__get__('_addRules')

      @query =
        data_source_id: 'CoreLogic'
        data_source_type: 'county'
        data_type: 'tax'
        list: 'general'

      @rules = [
        config:
          DataType: "Int"
          nullZero: true
        output: "Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"
      ,
        config:
          DataType: "Int"
          nullZero: true
        output: "Another Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"        
      ]

    it 'should have valid _addRules insert query, without a given order count', (done) ->
      expectedInsertRules = [
        config:
          DataType: "Int"
          nullZero: true
        output: "Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"
        data_source_id: "CoreLogic"
        list: "general"
        ordering: 0
      ,
        config: 
          DataType: "Int" 
          nullZero: true
        output: "Another Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"
        data_source_id: "CoreLogic"
        list: "general"
        ordering: 1
      ]

      @_addRulesFn(@query, @rules)

      @rulesTableSqlMock.insertSpy.calledOnce.should.be.true
      @rulesTableSqlMock.insertSpy.calledWith(expectedInsertRules).should.be.true
      done()


    it 'should have valid _addRules insert query, with a given order count', (done) ->
      count = [
        list: 'general'
        count: 1
      ,
        list: 'base'
        count: 3
        ]
      expectedInsertRules = [
        config:
          DataType: "Int"
          nullZero: true
        output: "Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"
        data_source_id: "CoreLogic"
        list: "general"
        ordering:2
      ,
        config:
          DataType: "Int"
          nullZero: true
        output: "Another Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"
        data_source_id: "CoreLogic"
        list: "general"
        ordering: 3
      ]

      @_addRulesFn(@query, @rules, count)

      @rulesTableSqlMock.insertSpy.calledOnce.should.be.true
      @rulesTableSqlMock.insertSpy.calledWith(expectedInsertRules).should.be.true
      done()


  describe 'rules', ->
    beforeEach ->
      @rulesTableSqlMock = new sqlMockUtil.SqlMock
        groupName: 'config'
        tableHandle: 'dataNormalization'

      svc.__set__('tables', @rulesTableSqlMock)

      @query =
        data_source_id: 'CoreLogic'
        data_source_type: 'county'
        data_type: 'tax'

      @rules = [
        config:
          DataType: "Int"
          nullZero: true
        output: "Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"
        list: 'general'
      ]

    it 'should have valid getRules query', (done) ->
      expectedQuery = """select * from "config_data_normalization" where""" +
      """ "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax'"""

      svc.getRules(@query.data_source_id, @query.data_source_type, @query.data_type)

      @rulesTableSqlMock.selectSpy.calledOnce.should.be.true
      @rulesTableSqlMock.whereSpy.calledOnce.should.be.true
      @rulesTableSqlMock.whereSpy.calledWith(@query).should.be.true

      done()

    it 'should have valid createRules query', (done) ->
      expectedQuery = """select max(ordering) as count, list from "config_data_normalization" where "data_source_id" = """ +
      """'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' group by "list" """.trim()

      svc.createRules(@query.data_source_id, @query.data_source_type, @query.data_type, @rules)
      @rulesTableSqlMock.toString().should.equal expectedQuery
      @rulesTableSqlMock.selectSpy.calledOnce.should.be.true
      @rulesTableSqlMock.groupBySpy.calledOnce.should.be.true
      @rulesTableSqlMock.whereSpy.calledOnce.should.be.true
      @rulesTableSqlMock.thenSpy().callCount.should.equal 2
      @rulesTableSqlMock.catchSpy().callCount.should.equal 1

      # first .then callback should perform insert
      @rulesTableSqlMock.insertSpy.calledOnce.should.be.false
      fn = @rulesTableSqlMock.getThenCallback(0)
      callback1_param = [
        list: 'general'
        count: 1
      ]
      fn(callback1_param)
      @rulesTableSqlMock.insertSpy.calledOnce.should.be.true

      done()

    it 'should have valid putRules query', (done) ->
      svc.__with__('dbs', sqlMockUtil.SqlMock.dbs)(
        =>
          expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax'"""

          svc.putRules(@query.data_source_id, @query.data_source_type, @query.data_type, @rules)

          @rulesTableSqlMock.toString().should.equal expectedQuery
          @rulesTableSqlMock.insertSpy.calledOnce.should.be.false
          @rulesTableSqlMock.deleteSpy.calledOnce.should.be.true
          @rulesTableSqlMock.getThenCallback(0)()
          @rulesTableSqlMock.getThenCallback(1)()
          @rulesTableSqlMock.insertSpy.calledOnce.should.be.true
          @rulesTableSqlMock.commitSpy.calledOnce.should.be.true

          done()
      )

    it 'should have valid deleteRules query', (done) ->
      expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax'"""

      svc.deleteRules(@query.data_source_id, @query.data_source_type, @query.data_type)

      @rulesTableSqlMock.toString().should.equal expectedQuery
      @rulesTableSqlMock.whereSpy.calledWith(@query).should.be.true
      @rulesTableSqlMock.deleteSpy.calledOnce.should.be.true
      @rulesTableSqlMock.thenSpy().callCount.should.equal 1
      @rulesTableSqlMock.catchSpy().callCount.should.equal 1


      fn = @rulesTableSqlMock.getThenCallback(0)
      fn(-1).should.be.false
      fn(0).should.be.true
      fn(1).should.be.true

      done()


  describe 'list rules', ->
    beforeEach ->
      @rulesTableSqlMock = new sqlMockUtil.SqlMock
        groupName: 'config'
        tableHandle: 'dataNormalization'

      svc.__set__('tables', @rulesTableSqlMock)

      @query =
        data_source_id: 'CoreLogic'
        data_source_type: 'county'
        data_type: 'tax'
        list: 'general'

      @rules = [
        config:
          DataType: "Int"
          nullZero: true
        output: "Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"
      ]

    it 'should have valid getListRules query', (done) ->
      expectedQuery = """select * from "config_data_normalization" where""" +
      """ "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' and "list" = 'general'"""

      svc.getListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list)

      @rulesTableSqlMock.toString().should.equal expectedQuery
      @rulesTableSqlMock.whereSpy.calledOnce.should.be.true
      @rulesTableSqlMock.whereSpy.calledWith(@query).should.be.true

      done()

    it 'should have valid createListRules query', (done) ->
      expectedQuery = """select max(ordering) as count, list from "config_data_normalization" where "data_source_id" = """ +
      """'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' group by "list" """.trim()

      svc.createRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @rules)
      @rulesTableSqlMock.toString().should.equal expectedQuery
      @rulesTableSqlMock.selectSpy.calledOnce.should.be.true
      @rulesTableSqlMock.groupBySpy.calledOnce.should.be.true
      @rulesTableSqlMock.whereSpy.calledOnce.should.be.true
      @rulesTableSqlMock.thenSpy().callCount.should.equal 2
      @rulesTableSqlMock.catchSpy().callCount.should.equal 1

      # first .then callback should perform insert
      @rulesTableSqlMock.insertSpy.calledOnce.should.be.false
      callback1_param = [
        list: 'general'
        count: 1
      ]
      fn = @rulesTableSqlMock.getThenCallback(0)
      fn(callback1_param)
      @rulesTableSqlMock.insertSpy.calledOnce.should.be.true

      done()

    it 'should have valid putListRules query', (done) ->
      svc.__with__('dbs', sqlMockUtil.SqlMock.dbs)(
        =>

          expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' and "list" = 'general'"""

          svc.putListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @rules)

          @rulesTableSqlMock.toString().should.equal expectedQuery
          @rulesTableSqlMock.insertSpy.calledOnce.should.be.false
          @rulesTableSqlMock.deleteSpy.calledOnce.should.be.true
          @rulesTableSqlMock.getThenCallback(0)()
          @rulesTableSqlMock.getThenCallback(1)()
          @rulesTableSqlMock.insertSpy.calledOnce.should.be.true
          @rulesTableSqlMock.commitSpy.calledOnce.should.be.true

          done()
      )

    it 'should have valid deleteListRules query', (done) ->
      expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' and "list" = 'general'"""

      svc.deleteListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list)

      @rulesTableSqlMock.toString().should.equal expectedQuery
      @rulesTableSqlMock.whereSpy.calledWith(@query).should.be.true
      @rulesTableSqlMock.deleteSpy.calledOnce.should.be.true

      fn = @rulesTableSqlMock.getThenCallback(0)
      fn(-1).should.be.false
      fn(0).should.be.true
      fn(1).should.be.true

      done()


  describe 'simple rule api', ->
    beforeEach ->
      @rulesTableSqlMock = new sqlMockUtil.SqlMock
        groupName: 'config'
        tableHandle: 'dataNormalization'

      svc.__set__('tables', @rulesTableSqlMock)

      @query =
        data_source_id: 'CoreLogic'
        data_source_type: 'county'
        data_type: 'tax'
        list: 'general'
        ordering: 0

      @rules = [
        config:
          DataType: "Int"
          nullZero: true
        output: "Int Param"
        input: "\"\""
        required: false
        data_source_type: "county"
        data_type: "tax"
      ]

    it 'should have valid getRule query', (done) ->
      expectedQuery = """select * from "config_data_normalization" where""" +
      """ "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' and "list" = 'general' and "ordering" = '0'"""

      svc.getRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering)

      @rulesTableSqlMock.toString().should.equal expectedQuery
      @rulesTableSqlMock.whereSpy.calledOnce.should.be.true
      @rulesTableSqlMock.whereSpy.calledWith(@query).should.be.true

      callbackParam = @rules
      fn = @rulesTableSqlMock.getThenCallback(0)
      fn(callbackParam).should.equal @rules[0]

      done()

    it 'should have valid updateRule query', (done) ->
      svc.updateRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering, @rules[0])

      @rulesTableSqlMock.updateSpy.calledOnce.should.be.true
      @rulesTableSqlMock.updateSpy.calledWith(_.extend(@rules[0], @query)).should.be.true
      @rulesTableSqlMock.whereSpy.calledOnce.should.be.true
      @rulesTableSqlMock.whereSpy.calledWith(@query).should.be.true
      @rulesTableSqlMock.thenSpy().callCount.should.equal 1
      @rulesTableSqlMock.catchSpy().callCount.should.equal 1

      fn = @rulesTableSqlMock.getThenCallback(0)
      fn(1).should.be.true
      fn(0).should.be.false

      done()

    it 'should have valid deleteRule query', (done) ->
      svc.__with__('dbs', sqlMockUtil.SqlMock.dbs)(
        =>

          expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' and "list" = 'general' and "ordering" = '0'"""

          svc.deleteRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering)

          @rulesTableSqlMock.toString().should.equal expectedQuery
          @rulesTableSqlMock.deleteSpy.calledOnce.should.be.true
          @rulesTableSqlMock.whereSpy.calledOnce.should.be.true
          @rulesTableSqlMock.whereSpy.calledWith(@query).should.be.true
          @rulesTableSqlMock.thenSpy().callCount.should.equal 1
          @rulesTableSqlMock.catchSpy().callCount.should.equal 1

          done()
      )
