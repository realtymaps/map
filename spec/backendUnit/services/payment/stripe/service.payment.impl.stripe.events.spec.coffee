require('chai').should()
sinon = require 'sinon'
Promise = require 'bluebird'
{basePath} = require '../../../globalSetup'
rewire = require 'rewire'
emailEvents = rewire "#{basePath}/services/email/vero/service.email.impl.vero.events"
subject = rewire "#{basePath}/services/payment/stripe/service.payment.impl.stripe.events"
paymentEvents = require "#{basePath}/enums/enum.payment.events"

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

    tables =
      auth:
        user: () ->
          mockUserTable
      event:
        history: () ->
          mockHistoryTable

    subject.__set__ 'tables', tables

    @stripe =
      events:
        retrieve: sinon.stub()

    @emailEvents = _.mapValues emailEvents(), () ->
      sinon.stub().returns(Promise.resolve())

    subject.__set__ 'emailPlatform', events: @emailEvents

  describe paymentEvents.customerSubscriptionVerified, ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionVerified)
      # console.log fileName
      eventData = require(fileName)
      # console.log "eventData"
      # console.log eventData, true
      @stripe.events.retrieve.returns(Promise.resolve eventData)

      @promise = subject(@stripe).handle(eventData)

    it "can run", ->
      @promise

    it "called", ->
      @stripe.events.retrieve.called.should.be.ok
      @emailEvents.subscriptionVerified.called.should.be.ok

    it 'opts', ->
      @emailEvents.subscriptionVerified.args[0][0].should.be.eql
        authUser: mockAuthUser
        plan: "standard"

  describe paymentEvents.customerSubscriptionDeleted, ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionDeleted)
      eventData = require(fileName)
      @stripe.events.retrieve.returns(Promise.resolve eventData)
      @promise = subject(@stripe).handle(eventData)

    it "can run", ->
      @promise

    it "called", ->
      @stripe.events.retrieve.called.should.be.ok
      @emailEvents.subscriptionDeleted.called.should.be.ok

    it 'opts', ->
      @emailEvents.subscriptionDeleted.args[0][0].should.be.eql
        authUser: mockAuthUser
        plan: "standard"

  describe paymentEvents.customerSubscriptionUpdated, ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionUpdated)
      eventData = require(fileName)
      @stripe.events.retrieve.returns(Promise.resolve eventData)
      @promise = subject(@stripe).handle(eventData)

    it "can run", ->
      @promise

    it "called", ->
      @stripe.events.retrieve.called.should.be.ok
      @emailEvents.subscriptionUpdated.called.should.be.ok

    it 'opts', ->
      @emailEvents.subscriptionUpdated.args[0][0].should.be.eql
        authUser: mockAuthUser
        plan: "standard"

  describe paymentEvents.customerSubscriptionTrialWillEnd, ->

    beforeEach ->
      fileName = jsonString.replace(":file", paymentEvents.customerSubscriptionTrialWillEnd)
      eventData = require(fileName)
      @stripe.events.retrieve.returns(Promise.resolve eventData)
      @promise = subject(@stripe).handle(eventData)

    it "can run", ->
      @promise

    it "called", ->
      @stripe.events.retrieve.called.should.be.ok
      @emailEvents.subscriptionTrialEnding.called.should.be.ok

    it 'opts', ->
      @emailEvents.subscriptionTrialEnding.args[0][0].should.be.eql
        authUser: mockAuthUser
        plan: "standard"
