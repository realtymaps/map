sinon = require 'sinon'
{expect,should} = require("chai")
should()
Promise = require 'bluebird'
_ = require 'lodash'
knex = require 'knex'
rewire = require 'rewire'
config = require '../../../backend/config/config'
svc = rewire '../../../backend/services/service.jobs'
SqlMock = require '../../specUtils/sqlMock.coffee'

describe 'service.jobs.spec.coffee', ->

  describe 'history service', ->
    beforeEach () =>
      @jobQueue_taskHistory = new SqlMock 'jobQueue', 'taskHistory'

      @dbs_main = new SqlMock 'dbs', 'main'
      @tables =
        jobQueue:
          taskHistory: () =>
            @jobQueue_taskHistory

      @mainDBS =
        get: () =>
          @dbs_main

      # rewire modules used directly inside service logic
      svc.__set__('dbs', @mainDBS)
      svc.__set__('tables', @tables)

    it 'should query history, defaults', (done) =>
      svc.jobStatGetters.taskHistory()
      @jobQueue_taskHistory.selectSpy.callCount.should.equal 0
      @jobQueue_taskHistory.whereRawSpy.calledOnce.should.be.true
      expect(@jobQueue_taskHistory.whereRawSpy.args[0][0]).to.equal "now_utc() - started <= interval '30 days'" # the default
      done()


  describe 'history error service', ->
    beforeEach () =>
      @jobQueue_subtaskErrorHistory = new SqlMock 'jobQueue', 'subtaskErrorHistory'

      @tables =
        jobQueue:
          subtaskErrorHistory: () =>
            @jobQueue_subtaskErrorHistory

      svc.__set__('tables', @tables)

    it 'should query history errors', (done) =>
      svc.jobStatGetters.subtaskErrorHistory()
      @jobQueue_subtaskErrorHistory.whereRawSpy.callCount.should.equal 1
      done()


  describe 'task service', ->
    beforeEach () =>
      @jobQueue_taskConfig = new SqlMock 'jobQueue', 'taskConfig'
      @jobQueue_subtaskConfig = new SqlMock 'jobQueue', 'subtaskConfig'

      @tables =
        jobQueue:
          taskConfig: () =>
            @jobQueue_taskConfig
          subtaskConfig: () =>
            @jobQueue_subtaskConfig

      # rewire modules used directly inside service logic
      svc.__set__('tables', @tables)

      # aquire service class to be tested
      TaskServiceClass = svc.__get__('TaskService')

      # create service instance to test on
      tasksTest = new TaskServiceClass @jobQueue_taskConfig.dbFn()

      # reset module 'tasks' object to this test instance
      svc.tasks = tasksTest

    it 'should query task service', (done) =>
      svc.tasks.getAll(name: "foo").then (d) =>
        expect(@jobQueue_taskConfig.whereRawSpy.callCount).to.equal 1
        done()

    it 'should delete subtasks', () =>
      svc.tasks.delete("foo").then () =>
        expect(@jobQueue_subtaskConfig.deleteSpy.callCount).to.equal 1


  describe 'health service', ->
    beforeEach ->
      @jobQueue_taskHistory = new SqlMock('jobQueue', 'taskHistory')
      @history_dataLoad = new SqlMock('history', 'dataLoad')
      @property_combined = new SqlMock('finalized', 'combined')
      @dbs_main = new SqlMock('dbs', 'main')

      @tables =
        jobQueue:
          taskHistory: () =>
            @jobQueue_taskHistory
        history:
          dataLoad: () =>
            @history_dataLoad

        finalized:
          combined: () =>
            @property_combined

      @mainDBS =
        get: () =>
          @dbs_main

      svc.__set__('dbs', @mainDBS)
      svc.__set__('tables', @tables)


    it 'should query history with defaults', (done) ->
      # sophisticated query containing subqueries, a cross-table join, and several 'raw' calls
      svc.jobStatGetters.health()

      # subquery #1
      @history_dataLoad.selectSpy.calledOnce.should.be.true
      expect(@history_dataLoad.selectSpy.args[0][0]).to.deep.equal @dbs_main # raw's via dbs_main

      @history_dataLoad.groupByRawSpy.calledOnce.should.be.true
      expect(@history_dataLoad.groupByRawSpy.args[0][0]).to.equal 'load_id'

      # no query param yields interval '30 days'
      @history_dataLoad.whereRawSpy.calledOnce.should.be.true
      expect(@history_dataLoad.whereRawSpy.args[0][0]).to.equal "now_utc() - rm_inserted_time <= interval '30 days'"

      @history_dataLoad.whereSpy.calledOnce.should.be.true
      expect(@history_dataLoad.whereSpy.args[0][0]).to.be.empty
      @history_dataLoad.asSpy.calledOnce.should.be.true


      # subquery #2
      @property_combined.selectSpy.calledOnce.should.be.true
      expect(@property_combined.selectSpy.args[0][0]).to.deep.equal @dbs_main

      @property_combined.groupByRawSpy.calledOnce.should.be.true
      expect(@property_combined.groupByRawSpy.args[0][0]).to.equal 'combined_id'

      @property_combined.whereRawSpy.callCount.should.equal 0
      expect(@property_combined.whereSpy.args[0][0]).to.be.empty
      @property_combined.asSpy.calledOnce.should.be.true


      # dbs_main (anon knex)
      @dbs_main.selectSpy.calledOnce.should.be.true
      expect(@dbs_main.selectSpy.args[0][0]).to.deep.equal '*'

      @dbs_main.fromSpy.calledOnce.should.be.true
      expect(@dbs_main.fromSpy.args[0][0]).to.deep.equal @history_dataLoad

      @dbs_main.leftJoinSpy.calledOnce.should.be.true
      expect(@dbs_main.leftJoinSpy.args[0][0]).to.deep.equal @property_combined

      @dbs_main.rawSpy.callCount.should.equal 13 # dbs_main calls all the 'raw'

      done()


    it 'should query history with correct query values', (done) ->
      timerangeTest = '1 day'
      svc.jobStatGetters.health(timerange: timerangeTest)
      expect(@history_dataLoad.whereRawSpy.args[0][0]).to.equal "now_utc() - rm_inserted_time <= interval '#{timerangeTest}'"

      @history_dataLoad.whereSpy.calledOnce.should.be.true
      expect(@history_dataLoad.whereSpy.args[0][0]).to.be.empty

      done()
