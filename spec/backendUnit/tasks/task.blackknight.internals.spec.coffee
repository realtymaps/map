_ = require 'lodash'
{should, expect}= require('chai')
should()
sinon = require 'sinon'
logger = require('../../specUtils/logger').spawn('task:blackknight')
rewire = require 'rewire'
Promise = require 'bluebird'
bkServiceInternals = rewire '../../../backend/tasks/task.blackknight.internals'
fixture = require '../../fixtures/backend/tasks/task.blackknight.internals'


_keystoreContext = {}
_keystore =
  getValue: (key, opts={}) -> Promise.try () ->
    if _keystoreContext[opts.namespace]? && key of _keystoreContext[opts.namespace]
      _keystoreContext[opts.namespace][key]
    else
      opts.defaultValue
  getValuesMap: (namespace, opts={}) -> Promise.try () ->
    _.defaults(_keystoreContext[namespace], opts.defaultValues)
  setValuesMap: (values, opts={}) -> Promise.try () ->
    _keystoreContext[opts.namespace] = values
  setValue: (key, value, opts={}) -> Promise.try () ->
    _keystoreContext[opts.namespace] ?= {}
    _keystoreContext[opts.namespace][key] = value

bkServiceInternals.__set__ 'keystore', _keystore


describe "task.blackknight.internal", () ->

  describe "processingDates", () ->

    it 'should pop fips from queue', (done) ->
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO] =
        "#{bkServiceInternals.DATES_QUEUED}": ['19800103', '19800102', '19800101']
        "#{bkServiceInternals.DATES_COMPLETED}": ['19800100']
        "#{bkServiceInternals.FIPS_QUEUED}": ['11111', '22222']
        "#{bkServiceInternals.CURRENT_PROCESS_DATE}": '19800101'

      bkServiceInternals.updateProcessInfo(date: "19800101", fips_code: '11111')
      .then () ->
        _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO].should.deep.equal
          "#{bkServiceInternals.DATES_QUEUED}": ['19800101', '19800102', '19800103']
          "#{bkServiceInternals.DATES_COMPLETED}": ['19800100']
          "#{bkServiceInternals.FIPS_QUEUED}": ['22222']
          "#{bkServiceInternals.CURRENT_PROCESS_DATE}": '19800101'
          "#{bkServiceInternals.MAX_DATE}": null
        done()

    it 'should pop fips and date from queues if last fips', (done) ->
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO] =
        "#{bkServiceInternals.DATES_QUEUED}": ['19800103', '19800102', '19800101']
        "#{bkServiceInternals.DATES_COMPLETED}": ['19800100']
        "#{bkServiceInternals.FIPS_QUEUED}": ['11111']
        "#{bkServiceInternals.CURRENT_PROCESS_DATE}": '19800101'

      bkServiceInternals.updateProcessInfo(date: "19800101", fips_code: '11111')
      .then () ->
        _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO].should.deep.equal
          "#{bkServiceInternals.DATES_QUEUED}": ['19800102', '19800103']
          "#{bkServiceInternals.DATES_COMPLETED}": ['19800100', '19800101']
          "#{bkServiceInternals.FIPS_QUEUED}": []
          "#{bkServiceInternals.CURRENT_PROCESS_DATE}": null
        done()

    it 'should populate fips queues if set', (done) ->
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO] =
        "#{bkServiceInternals.DATES_QUEUED}": ['19800103', '19800102']
        "#{bkServiceInternals.DATES_COMPLETED}": ['19800100', '19800101']
        "#{bkServiceInternals.FIPS_QUEUED}": []
        "#{bkServiceInternals.CURRENT_PROCESS_DATE}": null

      bkServiceInternals.updateProcessInfo(date: "19800102", fips_code: '11111', other_values: {"#{bkServiceInternals.FIPS_QUEUED}": ['11111', '22222', '33333']})
      .then () ->
        expected =
          "#{bkServiceInternals.DATES_QUEUED}": ['19800102', '19800103']
          "#{bkServiceInternals.DATES_COMPLETED}": ['19800100', '19800101']
          "#{bkServiceInternals.CURRENT_PROCESS_DATE}": null
          "#{bkServiceInternals.FIPS_QUEUED}": ['22222', '33333']
        _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO].should.deep.equal expected
        done()


    it 'should push given date to queue', (done) ->
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO] =
        "#{bkServiceInternals.DATES_QUEUED}": ['19800103', '19800102', '19800101']


      bkServiceInternals.pushProcessingDate("19800104")
      .then () ->
        _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.DATES_QUEUED].should.have.members [
          "19800101"
          "19800102"
          "19800103"
          "19800104"
        ]
        done()


  describe "_filterS3Contents", () ->
    it 'should correctly classify files', (done) ->
      inputContents = fixture._filterS3Contents.inputContents
      inputConfig = fixture._filterS3Contents.inputConfig
      outputFiltered = fixture._filterS3Contents.outputFiltered

      bkServiceInternals.__get__('_filterS3Contents')(inputContents, inputConfig)
      .then (filtered) ->
        expect(filtered).to.eql outputFiltered
        done()


  describe "getProcessInfo", () ->
    it 'should acquire and classify filenames to process by date and fips', (done) ->

      # rewire the calls to awsService.listObjects...
      awsListObjectResponses = fixture.getProcessInfo1.awsListObjectResponses
      revertAwsListObjects = bkServiceInternals.__set__ 'awsService',
        buckets:
          BlackknightData: 'aws-blackknight-data'
        listObjects: (opt) ->
          Promise.resolve(awsListObjectResponses[opt.Prefix])

      inputSubtask = fixture.getProcessInfo1.inputSubtask
      inputSubtaskStartTime = fixture.getProcessInfo1.inputSubtaskStartTime
      outputProcessInfo = fixture.getProcessInfo1.outputProcessInfo

      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.FIPS_QUEUED] = ['12099','99999']
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.CURRENT_PROCESS_DATE] = '20160406'
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.DELETE_BATCH_ID] = 'saved_batch_id'

      bkServiceInternals.getProcessInfo(inputSubtask, inputSubtaskStartTime)
      .then (processInfo) ->
        processInfo.should.deep.equal outputProcessInfo
        revertAwsListObjects()
        done()

    it 'should acquire and classify filenames to process by date without fips list', (done) ->

      # rewire the calls to awsService.listObjects...
      awsListObjectResponses = fixture.getProcessInfo2.awsListObjectResponses
      revertAwsListObjects = bkServiceInternals.__set__ 'awsService',
        buckets:
          BlackknightData: 'aws-blackknight-data'
        listObjects: (opt) ->
          Promise.resolve(awsListObjectResponses[opt.Prefix])

      inputSubtask = fixture.getProcessInfo2.inputSubtask
      inputSubtaskStartTime = fixture.getProcessInfo2.inputSubtaskStartTime
      outputProcessInfo = fixture.getProcessInfo2.outputProcessInfo

      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.DATES_QUEUED] = ['20160406', '20160407']
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.CURRENT_PROCESS_DATE] = '20110101'
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.FIPS_QUEUED] = []

      bkServiceInternals.getProcessInfo(inputSubtask, inputSubtaskStartTime)
      .then (processInfo) ->
        expect(processInfo).to.eql outputProcessInfo
        revertAwsListObjects()
        done()

    it 'should return proper response when no dates are available', (done) ->

      inputSubtask = fixture.getProcessInfo3.inputSubtask
      inputSubtaskStartTime = fixture.getProcessInfo3.inputSubtaskStartTime
      outputProcessInfo = fixture.getProcessInfo3.outputProcessInfo

      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.DATES_QUEUED] = []
      _keystoreContext[bkServiceInternals.BLACKKNIGHT_PROCESS_INFO][bkServiceInternals.FIPS_QUEUED] = []

      bkServiceInternals.getProcessInfo(inputSubtask, inputSubtaskStartTime)
      .then (processInfo) ->
        expect(processInfo).to.eql outputProcessInfo
        done()
