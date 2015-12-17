_ = require 'lodash'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.dataSourceRules.coffee'
tables = require '../../../backend/config/tables'
SqlMock = require '../../specUtils/sqlMock.coffee'


describe 'service.dataSourceRules.coffee', ->
  describe 'private api', ->
    beforeEach ->
      @rulesTableSqlMock = new SqlMock
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

      expect(@rulesTableSqlMock.insertSpy.calledOnce).to.be.true
      expect(@rulesTableSqlMock.insertSpy.calledWith(expectedInsertRules)).to.be.true
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

      expect(@rulesTableSqlMock.insertSpy.calledOnce).to.be.true
      expect(@rulesTableSqlMock.insertSpy.calledWith(expectedInsertRules)).to.be.true
      done()


  describe 'rules', ->
    beforeEach ->
      @rulesTableSqlMock = new SqlMock
        groupName: 'config'
        tableHandle: 'dataNormalization'
        result: [
          list: 'general'
          count: 1
        ]

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
      svc.getRules(@query.data_source_id, @query.data_source_type, @query.data_type).then (queryResults) =>
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.calledWith(@query)).to.be.true
        done()

    it 'should have valid createRules query', (done) ->
      calledWithArgs = [
        [
          [
            config:
              DataType:"Int"
              nullZero:true
            output:"Int Param"
            input:"\"\""
            required:false
            data_source_type:"county"
            data_type:"tax"
            list:"general"
            data_source_id:"CoreLogic"
            ordering:2
          ]
        ]
      ]

      svc.createRules(@query.data_source_id, @query.data_source_type, @query.data_type, @rules)
      .then (queryResults) =>
        expect(@rulesTableSqlMock.selectSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.groupBySpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.insertSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.insertSpy.args).to.deep.equal calledWithArgs
        done()

    it 'should have valid putRules query', (done) ->
      calledWithArgs = [
        [
          [
            config:
              DataType:"Int"
              nullZero:true
            output:"Int Param"
            input:"\"\""
            required:false
            data_source_type:"county"
            data_type:"tax"
            list:"general"
            data_source_id:"CoreLogic"
            ordering:0
          ]
        ]
      ]

      svc.__with__('dbs', SqlMock.dbs)(
        =>
          expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax'"""

          svc.putRules(@query.data_source_id, @query.data_source_type, @query.data_type, @rules)
          .then (queryResults) =>
            # @rulesTableSqlMock.insertSpy.calledOnce).to.be.false
            expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.insertSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.commitSpy.calledOnce).to.be.true
            @rulesTableSqlMock.insertSpy.calledWith(calledWithArgs).should.be.true
            done()
      )

    it 'should have valid deleteRules query', (done) ->
      expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax'"""

      svc.deleteRules(@query.data_source_id, @query.data_source_type, @query.data_type)
      .then (queryResults) =>
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
        expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true
        done()

    it 'should have valid result', (done) ->
      @rulesTableSqlMock.setResult 1
      svc.deleteRules(@query.data_source_id, @query.data_source_type, @query.data_type)
      .then (queryResults) =>
        expect(queryResults).to.be.true
        done()

    it 'should have invalid result', (done) ->
      @rulesTableSqlMock.setResult -1
      svc.deleteRules(@query.data_source_id, @query.data_source_type, @query.data_type)
      .then (queryResults) =>
        expect(queryResults).to.be.false
        done()


  describe 'list rules', ->
    beforeEach ->
      @rulesTableSqlMock = new SqlMock
        groupName: 'config'
        tableHandle: 'dataNormalization'
        result: [
          list: 'general'
          count: 1
        ]

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

      svc.getListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list).then (queryResults) =>
        @rulesTableSqlMock.toString().should.equal expectedQuery
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
        done()

    it 'should have valid createListRules query', (done) ->
      calledWithArgs = [
        [
          [
            config:
              DataType:"Int"
              nullZero:true
            output:"Int Param"
            input:"\"\""
            required:false
            data_source_type:"county"
            data_type:"tax"
            data_source_id:"CoreLogic"
            list:"general"
            ordering:2
          ]
        ]
      ]
      svc.createListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @rules).then (queryResults) =>
        expect(@rulesTableSqlMock.selectSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.groupBySpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.insertSpy.calledOnce).to.be.true 
        expect(@rulesTableSqlMock.insertSpy.args).to.deep.equal calledWithArgs
        done()

    it 'should have valid putListRules query', (done) ->
      calledWithArgs = [
        [
          [
            config:
              DataType:"Int"
              nullZero:true
            output:"Int Param"
            input:"\"\""
            required:false
            data_source_type:"county"
            data_type:"tax"
            data_source_id:"CoreLogic"
            list:"general"
            ordering:0
          ]
        ]
      ]
      svc.__with__('dbs', SqlMock.dbs)(
        =>
          svc.putListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @rules).then (queryResults) =>
            expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.insertSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.commitSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.insertSpy.args).to.deep.equal calledWithArgs
            expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
            done()
      )

    it 'should have valid deleteListRules query', (done) ->
      svc.deleteListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list).then (queryResults) =>
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
        expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true
        done()


  describe 'simple rule api', ->
    beforeEach ->
      @rulesTableSqlMock = new SqlMock
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
      @rulesTableSqlMock.setResult @rules
      svc.getRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering).then (queryResults) =>        
        expect(queryResults).to.equal @rules[0]
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
        done()

    it 'should have valid updateRule query', (done) ->
      svc.updateRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering, @rules[0]).then (queryResults) =>
        expect(@rulesTableSqlMock.updateSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.updateSpy.args).to.deep.equal [[_.extend(@rules[0], @query)]]
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
        done()

    it 'should have valid deleteRule query', (done) ->
      svc.__with__('dbs', SqlMock.dbs)(
        =>

          expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' and "list" = 'general' and "ordering" = '0'"""

          svc.deleteRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering).then (queryResults) =>
            @rulesTableSqlMock.toString().should.equal expectedQuery
            expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
            done()
      )
