require('chai').should()
sinon = require 'sinon'
Promise = require 'bluebird'
{basePath} = require '../../../globalSetup'
rewire = require 'rewire'
emailEvents = rewire "#{basePath}/services/email/vero/service.email.impl.vero.events"
subject = rewire "#{basePath}/services/payment/stripe/service.payment.impl.stripe.events"
paymentEvents = require "#{basePath}/enums/enum.vero.events"

subject.__set__ 'clsFullUrl', (arg) -> arg
SqlMock = require '../../../../specUtils/sqlMock'
_ = require "lodash"

mockAuthUser =
  id: 1
  first_name: "Bo"
  last_name: "Jackson"
  email: "boknows@gmail.com"
  email_validation_hash: "radarIsJammed"
  cancel_email_hash: "terminated"


jsonString = "../../../../fixtures/backend/services/stripe/:file.json"

describe "service.payment.impl.stripe.events", ->

  beforeEach ->

    mockUserTable = new SqlMock 'auth', 'user', result: [mockAuthUser]
    mockHistoryTable = new SqlMock 'event', 'history'
    mockProjectTable = new SqlMock 'user', 'project'

    @tables =
      auth:
        user: () ->
          mockUserTable
      event:
        history: () ->
          mockHistoryTable
      user:
        project: () ->
          mockProjectTable

    dbs =
      transaction: (main, cb) ->
        Promise.resolve(cb()) # fine to leave the `transaction` injected parameter undefined

    subject.__set__ 'tables', @tables
    subject.__set__ 'dbs', dbs
    @stripe =
      events:
        retrieve: sinon.stub()
      customers:
        retrieve: sinon.stub()
        deleteCard: sinon.stub()

    # override the vero event handlers to noop
    @emailEvents = _.mapValues emailEvents(), () ->
      sinon.stub().returns(Promise.resolve())
    subject.__set__ 'emailPlatform', events: @emailEvents


  describe paymentEvents.customerSubscriptionVerified, ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionVerified)
      eventData = require(fileName)
      @stripe.events.retrieve.returns(Promise.resolve eventData)
      @promise = subject(@stripe).handle(eventData)

    it "passes sanity check", ->
      @promise
      @stripe.events.retrieve.called.should.be.ok
      @emailEvents.subscriptionVerified.called.should.be.ok

    it "calls vero handler appropriately", ->
      @emailEvents.subscriptionVerified.args[0][0].should.be.eql(mockAuthUser)
      

  describe paymentEvents.customerSubscriptionDeleted + ".expired", ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionDeleted + ".expired")
      eventData = require(fileName)
      customer =
        id: mockAuthUser.id
        default_source: {}
      @stripe.events.retrieve.returns(Promise.resolve(eventData))
      @stripe.customers.retrieve.returns(Promise.resolve(customer))
      @stripe.customers.deleteCard.returns(Promise.resolve())
      @promise = subject(@stripe).handle(eventData)

    it "passes sanity check", ->

      @promise
      @stripe.events.retrieve.called.should.be.ok
      @stripe.customers.deleteCard.called.should.be.ok
      @emailEvents.subscriptionExpired.called.should.be.ok
      @tables.user.project().updateSpy.called.should.be.ok

    it 'calls vero handler appropriately', ->
      @emailEvents.subscriptionExpired.args[0][0].should.be.eql(mockAuthUser)


  describe paymentEvents.customerSubscriptionDeleted + ".deactivated", ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionDeleted + ".deactivated")
      eventData = require(fileName)
      @stripe.events.retrieve.returns(Promise.resolve eventData)
      @promise = subject(@stripe).handle(eventData)

    it "passes sanity check", ->
      @promise
      @stripe.events.retrieve.called.should.be.ok
      @emailEvents.subscriptionDeactivated.called.should.be.ok
      @tables.user.project().updateSpy.called.should.be.ok

    it 'calls vero handler appropriately', ->
      @emailEvents.subscriptionDeactivated.args[0][0].should.be.eql(mockAuthUser)


  describe paymentEvents.customerSubscriptionUpdated, ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionUpdated)
      eventData = require(fileName)
      @stripe.events.retrieve.returns(Promise.resolve eventData)
      @promise = subject(@stripe).handle(eventData)

    it "passes sanity check", ->
      @promise
      @stripe.events.retrieve.called.should.be.ok
      @emailEvents.subscriptionUpdated.called.should.be.ok

    it 'calls vero handler appropriately', ->
      @emailEvents.subscriptionUpdated.args[0][0].should.be.eql(mockAuthUser)


  describe paymentEvents.customerSubscriptionTrialWillEnd, ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionTrialWillEnd)
      eventData = require(fileName)
      @stripe.events.retrieve.returns(Promise.resolve eventData)
      @promise = subject(@stripe).handle(eventData)

    it "passes sanity check", ->
      @promise
      @stripe.events.retrieve.called.should.be.ok
      @emailEvents.subscriptionTrialEnding.called.should.be.ok

    it 'calls vero handler appropriately', ->
      @emailEvents.subscriptionTrialEnding.args[0][0].should.be.eql(mockAuthUser)
