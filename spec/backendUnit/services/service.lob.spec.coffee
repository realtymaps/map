sinon = require 'sinon'
{expect,should} = require("chai")
should()
Promise = require 'bluebird'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.lob'
SqlMock = require '../../specUtils/sqlMock.coffee'
logger = require('../../specUtils/logger').spawn('service.lob')
_ = require 'lodash'

mockAuthUser =
  id: 7
  first_name: "Bob"
  last_name: "McMailer"
  email: "blackhole@realtymaps.com"
  stripe_customer_id: 'cus_7r3jpOU0t3LQ9k'

mockCampaign = require '../../fixtures/backend/services/lob/mail.campaign.json'
mockPdfCampaign = _.extend {}, mockCampaign, aws_key: 'uploads/herpderp_l337.pdf'
mockLetter = require '../../fixtures/backend/services/lob/mail.letter.json'
mockPdfLetter = _.extend {}, mockLetter, options: aws_key: 'uploads/herpderp_l337.pdf'
mockLobLetter = require '../../fixtures/backend/services/lob/lob.letter.singlePage.json'
mockCustomer = require '../../fixtures/backend/services/stripe/customer.subscription.verified.json'
mockCharge = require '../../fixtures/backend/services/stripe/charge.uncaptured.json'

describe "service.lob", ->

  describe 'sending html campaigns', ->

    beforeEach ->

      user = new SqlMock 'auth', 'user', result: [mockAuthUser]
      campaigns = new SqlMock 'mail', 'campaign', results: [[mockCampaign],[mockCampaign]]
      letters = new SqlMock 'mail', 'letters', result: [mockLetter]

      @tables =
        auth:
          user: () -> user
        mail:
          campaign: () -> campaigns
          letters:  () -> letters

      svc.__set__ 'tables', @tables

      svc.__set__ 'dbs',
        transaction: (name, cb) -> cb()

      svc.__set__ 'paymentSvc',
        customers:
          get: -> Promise.try -> mockCustomer
          charge: -> Promise.try -> mockCharge

      svc.__set__ 'externalAccounts',
        getAccountInfo: -> Promise.try ->
          apiKey: 'abc123'
          other:
            test_api_key: 'test_abc123'

      svc.__set__ 'LobFactory',
        class
          letters:
            create: sinon.spy -> Promise.try -> mockLobLetter

      svc.__set__ 'awsService',
        getTimedDownloadUrl: (bucket, key) -> Promise.try ->
          return "http://aws-pdf-downloads/#{key}"
        buckets: PDF: 'aws-pdf-downloads'

    it 'should update campaign status and create letters', (done) ->

      svc.sendCampaign mockCampaign.id, mockAuthUser.id
      .then (campaign) =>

        @tables.auth.user().selectSpy.callCount.should.equal 1
        @tables.auth.user().whereSpy.args[0][0].should.deep.equal id: mockAuthUser.id

        @tables.mail.campaign().selectSpy.callCount.should.equal 2
        @tables.mail.campaign().whereSpy.args[0][0].should.deep.equal id: mockCampaign.id, auth_user_id: mockAuthUser.id

        @tables.mail.campaign().updateSpy.callCount.should.equal 1
        @tables.mail.campaign().updateSpy.args[0][0].should.deep.equal status: 'sending', stripe_charge: mockCharge
        @tables.mail.campaign().whereSpy.args[1][0].should.deep.equal id: mockCampaign.id, auth_user_id: mockAuthUser.id

        @tables.mail.letters().insertSpy.callCount.should.equal 1
        @tables.mail.letters().insertSpy.args[0][0].length.should.equal mockCampaign.recipients.length

        @tables.mail.letters().insertSpy.args[0][0][0].file.should.equal mockCampaign.lob_content
        @tables.mail.letters().insertSpy.args[0][0][0].lob_api.should.equal 'test'

        done()

    it 'should send html letter with valid `file` and `template` values', (done) ->
      svc.sendLetter mockLetter, 'test'
      .then (result) =>
        svc.__get__('lobPromise')()
        .then ({test}) ->
          test.letters.create.callCount.should.equal 1
          test.letters.create.args[0][0].file.should.equal mockLetter.file
          test.letters.create.args[0][0].template.should.be.true
          test.letters.create.args[0][0].color.should.be.false
          done()

  describe 'sending pdf campaigns', ->

    beforeEach ->

      user = new SqlMock 'auth', 'user', result: [mockAuthUser]
      campaigns = new SqlMock 'mail', 'campaign', results: [[mockPdfCampaign],[mockPdfCampaign]]
      letters = new SqlMock 'mail', 'letters', result: [mockPdfLetter]

      @tables =
        auth:
          user: () -> user
        mail:
          campaign: () -> campaigns
          letters:  () -> letters

      svc.__set__ 'tables', @tables

      svc.__set__ 'dbs',
        transaction: (name, cb) -> cb()

      svc.__set__ 'paymentSvc',
        customers:
          get: -> Promise.try -> mockCustomer
          charge: -> Promise.try -> mockCharge

      svc.__set__ 'externalAccounts',
        getAccountInfo: -> Promise.try ->
          apiKey: 'abc123'
          other:
            test_api_key: 'test_abc123'

      svc.__set__ 'LobFactory',
        class
          letters:
            create: sinon.spy -> Promise.try -> mockLobLetter

      svc.__set__ 'awsService',
        getTimedDownloadUrl: (bucket, key) -> Promise.try ->
          return "http://aws-pdf-downloads/#{key}"
        buckets: PDF: 'aws-pdf-downloads'

    it 'should update campaign status and create letters', (done) ->

      svc.sendCampaign mockPdfCampaign.id, mockAuthUser.id
      .then (campaign) =>

        @tables.auth.user().selectSpy.callCount.should.equal 1
        @tables.auth.user().whereSpy.args[0][0].should.deep.equal id: mockAuthUser.id

        @tables.mail.campaign().selectSpy.callCount.should.equal 2
        @tables.mail.campaign().whereSpy.args[0][0].should.deep.equal id: mockPdfCampaign.id, auth_user_id: mockAuthUser.id

        @tables.mail.campaign().updateSpy.callCount.should.equal 1
        @tables.mail.campaign().updateSpy.args[0][0].should.deep.equal status: 'sending', stripe_charge: mockCharge
        @tables.mail.campaign().whereSpy.args[1][0].should.deep.equal id: mockPdfCampaign.id, auth_user_id: mockAuthUser.id

        @tables.mail.letters().insertSpy.callCount.should.equal 1
        @tables.mail.letters().insertSpy.args[0][0].length.should.equal mockPdfCampaign.recipients.length

        @tables.mail.letters().insertSpy.args[0][0][0].file.should.equal mockPdfCampaign.lob_content
        @tables.mail.letters().insertSpy.args[0][0][0].lob_api.should.equal 'test'
        @tables.mail.letters().insertSpy.args[0][0][0].options.aws_key.should.equal mockPdfCampaign.aws_key

        done()

    it 'should send pdf letter with valid `file` and `template` values', (done) ->
      svc.sendLetter mockPdfLetter, 'test'
      .then (result) =>
        svc.__get__('lobPromise')()
        .then ({test}) ->
          test.letters.create.callCount.should.equal 1
          test.letters.create.args[0][0].file.should.equal "http://aws-pdf-downloads/uploads/herpderp_l337.pdf"
          test.letters.create.args[0][0].template.should.be.false
          test.letters.create.args[0][0].color.should.be.true
          done()
