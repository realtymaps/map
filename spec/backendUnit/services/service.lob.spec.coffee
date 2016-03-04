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

      svc.__set__ 'dbs', transaction: (name, cb) -> cb()

      @paymentSvc = customers:
        get: -> Promise.try -> mockCustomer
        charge: -> Promise.try -> mockCharge

      svc.__set__ 'paymentSvc', @paymentSvc

      svc.__set__ 'externalAccounts', getAccountInfo: Promise.try ->
      lobSvc = letters:
        create: -> Promise.try -> mockLobLetter

      svc.__set__ 'lobPromise', -> Promise.try ->
        test: lobSvc
        live: lobSvc

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

        @tables.mail.letters().insertSpy.args[0][0][0].options.template.should.equal true

        done()

  describe 'sending pdf campaigns', ->

    beforeEach ->

      user = new SqlMock 'auth', 'user', result: [mockAuthUser]
      campaigns = new SqlMock 'mail', 'campaign', results: [[mockPdfCampaign],[mockPdfCampaign]]
      letters = new SqlMock 'mail', 'letters', result: [mockLetter]

      @tables =
        auth:
          user: () -> user
        mail:
          campaign: () -> campaigns
          letters:  () -> letters

      svc.__set__ 'tables', @tables

      svc.__set__ 'dbs', transaction: (name, cb) -> cb()

      @paymentSvc = customers:
        get: -> Promise.try -> mockCustomer
        charge: -> Promise.try -> mockCharge

      svc.__set__ 'paymentSvc', @paymentSvc

      svc.__set__ 'externalAccounts', getAccountInfo: Promise.try ->
      lobSvc = letters:
        create: -> Promise.try -> mockLobLetter

      svc.__set__ 'lobPromise', -> Promise.try ->
        test: lobSvc
        live: lobSvc

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
        @tables.mail.campaign().whereSpy.args[0][0].should.deep.equal id: mockCampaign.id, auth_user_id: mockAuthUser.id

        @tables.mail.campaign().updateSpy.callCount.should.equal 1
        @tables.mail.campaign().updateSpy.args[0][0].should.deep.equal status: 'sending', stripe_charge: mockCharge
        @tables.mail.campaign().whereSpy.args[1][0].should.deep.equal id: mockCampaign.id, auth_user_id: mockAuthUser.id

        @tables.mail.letters().insertSpy.callCount.should.equal 1
        @tables.mail.letters().insertSpy.args[0][0].length.should.equal mockCampaign.recipients.length

        @tables.mail.letters().insertSpy.args[0][0][0].file.should.contain mockPdfCampaign.aws_key

        done()

    it 'should prepare pdf letters with valid `file` and `template` values', (done) ->
      mockLetter.file = 'uploads/herpderp_l337.pdf'
      svc.__get__('prepareLobLetter')(mockLetter)
      .then ({letter, lob}) ->
        letter.file.should.equal "http://aws-pdf-downloads/uploads/herpderp_l337.pdf"
        letter.template.should.be.false
        done()
