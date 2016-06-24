{should, expect}= require('chai')
should()
sinon = require 'sinon'
Promise = require 'bluebird'
SqlMock = require '../../specUtils/sqlMock.coffee'
logger = require('../../specUtils/logger').spawn('task.lob')
rewire = require 'rewire'
svc = rewire "../../../backend/tasks/task.lob"
_ = require 'lodash'

mockCampaign = require '../../fixtures/backend/services/lob/mail.campaign.json'
mockLetter = require '../../../backend/json/mail.fakeLetter.json'
mockLobLetter = require '../../fixtures/backend/services/lob/lob.letter.singlePage.json'

describe 'task.lob', ->
  beforeEach ->

    @letters = [mockLetter, mockLetter]

    campaigns = new SqlMock 'mail', 'campaign', result: [mockCampaign]
    letters = new SqlMock 'mail', 'letters', results: [@letters, []]

    @tables =
      mail:
        campaign: () -> campaigns
        letters:  () -> letters

    svc.__set__ 'tables', @tables

    @lobSvc =
      sendLetter: sinon.spy (letter) -> Promise.try ->
        mockLobLetter
      listLetters: sinon.spy () -> Promise.try -> data: []

    svc.__set__ 'lobSvc', @lobSvc

    @jobQueue = queueSubsequentSubtask: sinon.spy ({transaction, subtask, laterSubtaskName, manualData, replace}) ->
      manualData

    svc.__set__ 'jobQueue', @jobQueue

    svc.__set__ 'dbs', transaction: (name, cb) -> cb()

    svc.__set__ 'awsService',
      getTimedDownloadUrl: (bucket, key) -> Promise.try ->
        return "http://aws-pdf-downloads/#{key}"
      buckets: PDF: 'aws-pdf-downloads'

    @subtasks =
      findLetters:
        name: 'lob_findLetters'
        batch_id: 'ikpzfxu5'
      createLetter:
        name: 'lob_createLetter'
        batch_id: 'ikpzfxu5'
        data: mockLetter

  it 'exists', ->
    expect(svc).to.be.ok

  it 'should find letters and enqueue them as subtasks', ->
    svc.executeSubtask(@subtasks.findLetters)
    .then () =>
      @tables.mail.letters().selectSpy.callCount.should.equal 2
      @tables.mail.letters().whereSpy.args[0].should.deep.equal ['status', 'ready']
      @jobQueue.queueSubsequentSubtask.callCount.should.equal @letters.length
      expect(@jobQueue.queueSubsequentSubtask.args[0][0].transaction).to.be.undefined
      @jobQueue.queueSubsequentSubtask.args[0][0].subtask.should.equal @subtasks.findLetters
      @jobQueue.queueSubsequentSubtask.args[0][0].laterSubtaskName.should.equal 'createLetter'
      @jobQueue.queueSubsequentSubtask.args[0][0].manualData.should.equal mockLetter

  it 'send a letter and capture LOB response', ->
    svc.executeSubtask(@subtasks.createLetter)
    .then () =>
      @lobSvc.sendLetter.callCount.should.equal 1
      @lobSvc.sendLetter.args[0][0].should.equal mockLetter
      @tables.mail.letters().updateSpy.callCount.should.deep.equal 1
      @tables.mail.letters().updateSpy.args[0][0].should.deep.equal
        lob_response: mockLobLetter
        status: 'sent'
        retries: mockLetter.retries + 1
      @tables.mail.letters().whereSpy.args[0][0].should.deep.equal id: mockLetter.id
