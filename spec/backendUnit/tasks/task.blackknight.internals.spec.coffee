_ = require 'lodash'
{should, expect}= require('chai')
should()
# sinon = require 'sinon'
logger = require('../../specUtils/logger').spawn('task:blackknight')
rewire = require 'rewire'
Promise = require 'bluebird'
bkServiceInternals = rewire '../../../backend/tasks/task.blackknight.internals'

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
