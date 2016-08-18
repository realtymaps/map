_ = require 'lodash'
{should, expect}= require('chai')
should()
sinon = require 'sinon'
logger = require('../../specUtils/logger').spawn('task:blackknight')
rewire = require 'rewire'
Promise = require 'bluebird'
bkServiceInternals = rewire '../../../backend/tasks/task.blackknight.internals'
fixture = require '../../fixtures/backend/tasks/task.blackknight.internals'


_initialDateQueue =
  "#{bkServiceInternals.REFRESH}": ['19800103', '19800102', '19800101']
  "#{bkServiceInternals.UPDATE}": ['19900101', '19900102', '19900103']

_processDateQueue = {} # set this beforeEach test

_keystore =
  getValuesMap: () -> Promise.try () ->
    return _processDateQueue
  setValuesMap: (currentDateQueue) -> Promise.try () ->
    _processDateQueue = currentDateQueue

bkServiceInternals.__set__ 'keystore', _keystore


describe "task.blackknight.internal", () ->

  describe "nextProcessingDates", () ->
    it 'should return latest date from queue', (done) ->
      _processDateQueue = _.cloneDeep _initialDateQueue
      expectedDates =
        "Refresh": "19800101"
        "Update": "19900101"

      bkServiceInternals.nextProcessingDates()
      .then (dates) ->
        dates.should.deep.equal expectedDates
        done()


  describe "popProcessingDates", () ->
    it 'should return popped date from queue', (done) ->
      _processDateQueue = _.cloneDeep _initialDateQueue
      expectedDates =
        "Refresh": "19800101"
        "Update": "19900101"

      expectedQueue =
        "Refresh": [
          "19800103",
          "19800102"
        ]
        "Update": [
          "19900103",
          "19900102"
        ]

      input =
        "Refresh": "19800101"
        "Update": "19900101"

      bkServiceInternals.popProcessingDates(input)
      .then (dates) ->
        dates.should.deep.equal expectedDates
        _processDateQueue['Refresh'].should.have.members expectedQueue['Refresh']
        _processDateQueue['Update'].should.have.members expectedQueue['Update']
        done()


  describe "pushProcessingDates", () ->
    it 'should push given date to queue', (done) ->
      _processDateQueue = _.cloneDeep _initialDateQueue

      expectedQueue =
        "Refresh": [
          "19800101"
          "19800102"
          "19800103"
          "19800104"
        ]
        "Update": [
          "19900101"
          "19900102"
          "19900103"
          "19900104"
        ]

      input =
        "Refresh": "19800104"
        "Update": "19900104"

      bkServiceInternals.pushProcessingDates(input)
      .then () ->
        _processDateQueue['Refresh'].should.have.members expectedQueue['Refresh']
        _processDateQueue['Update'].should.have.members expectedQueue['Update']
        done()


  describe "filterS3Contents", () ->
    it 'should correctly classify files', (done) ->
      inputContents = fixture.filterS3Contents.inputContents
      inputConfig = fixture.filterS3Contents.inputConfig
      outputFiltered = fixture.filterS3Contents.outputFiltered

      bkServiceInternals.filterS3Contents(inputContents, inputConfig)
      .then (filtered) ->
        expect(filtered).to.eql outputFiltered
        done()


  describe "getProcessInfo", () ->
    it 'should acquire and classify filenames to process', (done) ->

      revert = bkServiceInternals.__set__ 'nextProcessingDates', () ->
        _processDates = {
          "Refresh": "20160406",
          "Update": "20160406"
        }
        Promise.resolve(_processDates)

      inputSubtask = fixture.getProcessInfo.inputSubtask
      inputSubtaskStartTime = fixture.getProcessInfo.inputSubtaskStartTime
      outputProcessInfo = fixture.getProcessInfo.outputProcessInfo

      bkServiceInternals.getProcessInfo(inputSubtask, inputSubtaskStartTime)
      .then (processInfo) ->
        expect(processInfo).to.eql outputProcessInfo
        revert()
        done()

  # describe "useProcessInfo", () ->
  #   Might be able to test things like fips-code structure, but this routine mostly just
  #   branches off into calls to other routines in parallel fashion


  describe "queuePerFileSubtasks", () ->
    beforeEach ->

      @jobQueueSpy =
        queueSubsequentSubtask: sinon.spy (opts) ->
          Promise.resolve()
      @revert = bkServiceInternals.__set__ 'jobQueue', @jobQueueSpy

    it 'should queue correct subtasks when action = DELETE', (done) ->
      inputTransaction = fixture.queuePerFileSubtasks.inputTransaction1
      inputSubtask = fixture.queuePerFileSubtasks.inputSubtask1
      inputFiles = fixture.queuePerFileSubtasks.inputFiles1
      inputAction = fixture.queuePerFileSubtasks.inputAction1

      loadRawDataTaskArgs = fixture.queuePerFileSubtasks.loadRawDataTaskArgs1
      recordChangeCountsTaskArgs = fixture.queuePerFileSubtasks.recordChangeCountsTaskArgs1

      bkServiceInternals.queuePerFileSubtasks(inputTransaction, inputSubtask, inputFiles, inputAction)
      .then (fipsCodes) =>
        expect(fipsCodes).to.be.empty
        expect(@jobQueueSpy.queueSubsequentSubtask.args[0][0]).to.eql loadRawDataTaskArgs
        expect(@jobQueueSpy.queueSubsequentSubtask.args[1][0]).to.eql recordChangeCountsTaskArgs
        @revert()
        done()



    it 'should queue correct subtasks when action = DELETE', (done) ->
      inputTransaction = fixture.queuePerFileSubtasks.inputTransaction2
      inputSubtask = fixture.queuePerFileSubtasks.inputSubtask2
      inputFiles = fixture.queuePerFileSubtasks.inputFiles2
      inputAction = fixture.queuePerFileSubtasks.inputAction2

      loadRawDataTaskArgs = fixture.queuePerFileSubtasks.loadRawDataTaskArgs2
      recordChangeCountsTaskArgs = fixture.queuePerFileSubtasks.recordChangeCountsTaskArgs2

      outputFipsCodes = {"12021":true}

      bkServiceInternals.queuePerFileSubtasks(inputTransaction, inputSubtask, inputFiles, inputAction)
      .then (fipsCodes) =>
        expect(fipsCodes).to.eql outputFipsCodes
        expect(@jobQueueSpy.queueSubsequentSubtask.args[0][0]).to.eql loadRawDataTaskArgs
        expect(@jobQueueSpy.queueSubsequentSubtask.args[1][0]).to.eql recordChangeCountsTaskArgs
        @revert()
        done()

