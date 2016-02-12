sinon = require 'sinon'
{expect,should} = require("chai")
should()
Promise = require 'bluebird'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.lob'
SqlMock = require '../../specUtils/sqlMock.coffee'
logger = require('../../specUtils/logger').spawn('service.lob')

mockAuthUser =
  id: 7
  first_name: "Bob"
  last_name: "McMailer"
  email: "blackhole@realtymaps.com"
  stripe_customer_id: 'cus_7r3jpOU0t3LQ9k'

mockCampaign = require '../../fixtures/backend/services/lob/mail.campaign.json'
mockLetter = require '../../fixtures/backend/services/lob/mail.letter.json'
mockLobLetter = require '../../fixtures/backend/services/lob/lob.letter.singlePage.json'
mockCustomer = require '../../fixtures/backend/services/stripe/customer.subscription.verified.json'
mockCharge = require '../../fixtures/backend/services/stripe/charge.uncaptured.json'

describe "service.lob", ->

  beforeEach ->

    user = new SqlMock 'auth', 'user', result: [mockAuthUser]
    campaigns = new SqlMock 'mail', 'campaign', result: [mockCampaign]
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

  describe 'sending valid campaign', ->

    # this.timeout(10000)

    it 'should update status and create letters', (done) ->

      svc.sendCampaign mockCampaign.id, mockAuthUser.id
      .then (campaign) =>

        @tables.auth.user().selectSpy.callCount.should.equal 1
        @tables.auth.user().whereSpy.args[0][0].should.deep.equal id: mockAuthUser.id

        whereSpy = @tables.mail.campaign().whereSpy

        @tables.mail.campaign().selectSpy.callCount.should.equal 1
        @tables.mail.campaign().whereSpy.args[0][0].should.deep.equal id: mockCampaign.id, auth_user_id: mockAuthUser.id

        @tables.mail.campaign().updateSpy.callCount.should.equal 1
        @tables.mail.campaign().updateSpy.args[0][0].should.deep.equal status: 'sending', stripe_charge: mockCharge
        @tables.mail.campaign().whereSpy.args[1][0].should.deep.equal id: mockCampaign.id, auth_user_id: mockAuthUser.id

        @tables.mail.letters().insertSpy.callCount.should.equal 1
        @tables.mail.letters().insertSpy.args[0][0].length.should.equal mockCampaign.recipients.length

        done()
