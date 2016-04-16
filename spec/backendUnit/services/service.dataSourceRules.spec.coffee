_ = require 'lodash'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.dataSourceRules.coffee'
SqlMock = require '../../specUtils/sqlMock.coffee'
{should, expect} = require "chai"
should()


describe 'service.dataSourceRules.coffee', ->
  describe 'private api', ->
    beforeEach ->
      @rulesTableSqlMock = new SqlMock 'config', 'dataNormalization'
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

    it 'should have valid _addRules insert query, without a given order count', () ->
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



    it 'should have valid _addRules insert query, with a given order count', () ->
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



  describe 'rules', ->
    beforeEach ->
      @rulesTableSqlMock = new SqlMock 'config', 'dataNormalization',
        debug: false
        results: [
          [list: 'general', count: 1],  # first part of transaction via select query supplying "count"
          [rowCount: 1]  # second part of transaction via insert query supplying "rowCount"
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

    it 'should have valid getRules query', () ->
      this.timeout(5000)
      svc.getRules(@query.data_source_id, @query.data_source_type, @query.data_type).then (queryResults) =>
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.calledWith(@query)).to.be.true


    it 'should have valid createRules query', () ->
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


    it 'should have valid putRules query', () ->
      calledWithArgs =
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

      svc.__with__('dbs', SqlMock.dbs)(
        =>
          expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax'"""
          svc.putRules(@query.data_source_id, @query.data_source_type, @query.data_type, @rules)
          .then (queryResults) =>
            # @rulesTableSqlMock.insertSpy.calledOnce).to.be.false
            expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.insertSpy.calledOnce).to.be.true
            @rulesTableSqlMock.insertSpy.args[0][0][0].should.be.eql calledWithArgs
      )

    it 'should have valid deleteRules query', () ->
      expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax'"""

      svc.deleteRules(@query.data_source_id, @query.data_source_type, @query.data_type)
      .then (queryResults) =>
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
        expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true

    it 'should have valid result', () ->
      @rulesTableSqlMock.setResult 1
      svc.deleteRules(@query.data_source_id, @query.data_source_type, @query.data_type)
      .then (queryResults) =>
        expect(queryResults).to.be.true

    it 'should have invalid result', () ->
      @rulesTableSqlMock.setResult -1
      svc.deleteRules(@query.data_source_id, @query.data_source_type, @query.data_type)
      .then (queryResults) =>
        expect(queryResults).to.be.false


  describe 'list rules', ->
    beforeEach ->
      @rulesTableSqlMock = new SqlMock 'config', 'dataNormalization',
        results: [
          [list: 'general', count: 1],  # first part of transaction via select query supplying "count"
          [rowCount: 1]  # second part of transaction via insert query supplying "rowCount"
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

    it 'should have valid getListRules query', () ->
      expectedQuery = """select * from "config_data_normalization" where""" +
      """ "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' and "list" = 'general'"""

      svc.getListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list).then (queryResults) =>
        @rulesTableSqlMock.toString().should.equal expectedQuery
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]

    it 'should have valid createListRules query', () ->
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

    it 'should have valid putListRules query', () ->
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
            expect(@rulesTableSqlMock.insertSpy.args).to.deep.equal calledWithArgs
            expect(@rulesTableSqlMock.whereSpy.args[0]).to.deep.equal [@query]

      )

    it 'should have valid deleteListRules query', () ->
      svc.deleteListRules(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list).then (queryResults) =>
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]
        expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true


  describe 'simple rule api', ->
    beforeEach ->
      @rulesTableSqlMock = new SqlMock 'config', 'dataNormalization'
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

    it 'should have valid getRule query', () ->
      @rulesTableSqlMock.setResult @rules
      svc.getRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering).then (queryResults) =>
        expect(queryResults).to.equal @rules[0]
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]


    it 'should have valid updateRule query', () ->
      svc.updateRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering, @rules[0]).then (queryResults) =>
        expect(@rulesTableSqlMock.updateSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.updateSpy.args).to.deep.equal [[_.extend(@rules[0], @query)]]
        expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
        expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]


    it 'should have valid deleteRule query', () ->
      svc.__with__('dbs', SqlMock.dbs)(
        =>

          expectedQuery = """delete from "config_data_normalization" where "data_source_id" = 'CoreLogic' and "data_source_type" = 'county' and "data_type" = 'tax' and "list" = 'general' and "ordering" = '0'"""

          svc.deleteRule(@query.data_source_id, @query.data_source_type, @query.data_type, @query.list, @query.ordering).then (queryResults) =>
            @rulesTableSqlMock.toString().should.equal expectedQuery
            expect(@rulesTableSqlMock.deleteSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.whereSpy.calledOnce).to.be.true
            expect(@rulesTableSqlMock.whereSpy.args).to.deep.equal [[@query]]

      )
