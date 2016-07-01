require('chai').should()
sinon = require 'sinon'
Promise = require 'bluebird'
{basePath, commonPath} = require '../../../globalSetup'
rewire = require 'rewire'
subject = rewire "#{basePath}/services/email/vero/service.email.impl.vero.events"
internals = null
paymentEvents = require "#{basePath}/enums/enum.vero.events"
emailRoutes = require("#{commonPath}/config/routes.backend").email
Case = require 'case'
mockCls = require '../../../../specUtils/mockCls'
routeHelpers = require "#{basePath}/utils/util.route.helpers"



describe "service.email.impl.vero.events", ->

  afterEach ->
    @cls.kill()

  beforeEach ->
    @cls = mockCls()
    @cls.addItem 'req',
      protocol:  "http"
      get: () ->
        "127.0.0.1"


    @vero =
      createUserAndTrackEvent: sinon.stub().returns(Promise.resolve())

    internals = require("#{basePath}/services/email/vero/service.email.impl.vero.events.internals")(@vero)

    @authUser =
      first_name: "Bo"
      last_name: "Jackson"
      email: ".nows@gmail.com"
      email_validation_hash: "radarIsJammed"
      cancel_email_hash: "terminated"

  describe "subscriptionSignUp", ->

    beforeEach ->
      @promise = subject(@vero).subscriptionSignUp(authUser: @authUser, plan: 'standard')

    it "can run", ->
      @promise

    it "is called", ->
      @vero.createUserAndTrackEvent.called.should.be.ok

    it "id" , ->
      @vero.createUserAndTrackEvent.args[0][0].should.be.eql @authUser.email

    it "email" , ->
      @vero.createUserAndTrackEvent.args[0][1].should.be.eql @authUser.email

    it "userData" , ->
      @vero.createUserAndTrackEvent.args[0][2].should.be.eql
        first_name: @authUser.first_name
        last_name: @authUser.last_name
        subscription_status: 'trial'

    it "eventName" , ->
      @vero.createUserAndTrackEvent.args[0][3].should.be.eql paymentEvents.customerSubscriptionCreated

    it "eventData" , ->
      @vero.createUserAndTrackEvent.args[0][4].should.be.eql
        verify_url: routeHelpers.clsFullUrl emailRoutes.verify.replace(":hash", @authUser.email_validation_hash)
        in_error_support_phrase: internals.inErrorSupportPhrase

  describe "subscriptionTrialEnding", ->

    beforeEach ->
      @promise = subject(@vero).subscriptionTrialEnding(authUser: @authUser, plan: 'standard')

    it "can run", ->
      @promise

    it "is called", ->
      @vero.createUserAndTrackEvent.called.should.be.ok

    it "id" , ->
      @vero.createUserAndTrackEvent.args[0][0].should.be.eql @authUser.email

    it "email" , ->
      @vero.createUserAndTrackEvent.args[0][1].should.be.eql @authUser.email

    it "userData" , ->
      @vero.createUserAndTrackEvent.args[0][2].should.be.eql
        first_name: @authUser.first_name
        last_name: @authUser.last_name
        subscription_status: 'trial'

    it "eventName" , ->
      @vero.createUserAndTrackEvent.args[0][3].should.be.eql paymentEvents.customerSubscriptionTrialWillEnd

    it "eventData" , ->
      @vero.createUserAndTrackEvent.args[0][4].should.be.eql
        cancel_plan_url: routeHelpers.clsFullUrl emailRoutes.cancelPlan.replace(":cancelPlan", @authUser.cancel_email_hash)
        in_error_support_phrase: internals.inErrorSupportPhrase

  [
    'subscriptionVerified'
    'subscriptionUpdated'
    'subscriptionDeleted'
  ].forEach (testName) ->
    describe testName, ->

      beforeEach ->
        @promise = subject(@vero)[testName](authUser: @authUser, plan: 'standard')

      it "can run", ->
        @promise

      it "is called", ->
        @vero.createUserAndTrackEvent.called.should.be.ok

      it "id" , ->
        @vero.createUserAndTrackEvent.args[0][0].should.be.eql @authUser.email

      it "email" , ->
        @vero.createUserAndTrackEvent.args[0][1].should.be.eql @authUser.email

      it "userData" , ->
        @vero.createUserAndTrackEvent.args[0][2].should.be.eql
          first_name: @authUser.first_name
          last_name: @authUser.last_name
          subscription_status: 'trial'

      it "eventName" , ->
        name = 'customer' + Case.pascal testName
        event = paymentEvents[name] || paymentEvents[testName]
        @vero.createUserAndTrackEvent.args[0][3].should.be.eql event

      it "eventData" , ->
        @vero.createUserAndTrackEvent.args[0][4].should.be.eql
          in_error_support_phrase: internals.inErrorSupportPhrase

  testName = 'notificationPropertiesSaved'
  describe testName, ->

    beforeEach ->
      @promise = subject(@vero)[testName] {
        authUser: @authUser
        properties: []
      }

    it "can run", ->
      @promise

    it "is called", ->
      @vero.createUserAndTrackEvent.called.should.be.ok

    it "id" , ->
      @vero.createUserAndTrackEvent.args[0][0].should.be.eql @authUser.email

    it "email" , ->
      @vero.createUserAndTrackEvent.args[0][1].should.be.eql @authUser.email

    it "userData" , ->
      @vero.createUserAndTrackEvent.args[0][2].should.be.eql
        first_name: @authUser.first_name
        last_name: @authUser.last_name
        subscription_status: 'trial'

    it "eventName" , ->
      @vero.createUserAndTrackEvent.args[0][3].should.be.eql paymentEvents.notificationPropertiesSaved

    it "eventData" , ->
      @vero.createUserAndTrackEvent.args[0][4].should.be.eql {
        in_error_support_phrase: internals.inErrorSupportPhrase
        properties: []
      }
