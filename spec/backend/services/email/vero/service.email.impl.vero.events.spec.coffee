require 'should'
sinon = require 'sinon'
Promise = require 'bluebird'
basePath = require '../../../basePath'
commonPath = require '../../../commonPath'
rewire = require 'rewire'
subject = rewire "#{basePath}/services/email/vero/service.email.impl.vero.events"
paymentEvents = require "#{basePath}/enums/enum.payment.events"
emailRoutes = require("#{commonPath}/config/routes.backend").email
Case = require 'case'
subject.__set__ 'clsFullUrl', (arg) -> arg

describe "service.email.impl.vero.events", ->

  beforeEach ->
    @vero =
      createUserAndTrackEvent: sinon.stub().returns(Promise.resolve())

    @authUser =
      first_name: "Bo"
      last_name: "Jackson"
      email: "boknows@gmail.com"
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
        verify_url: emailRoutes.verify.replace(":hash", @authUser.email_validation_hash)
        in_error_support_phrase: subject.__get__ 'inErrorSupportPhrase'

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
        cancel_plan_url: emailRoutes.cancelPlan.replace(":cancelPlan", @authUser.cancel_email_hash)
        in_error_support_phrase: subject.__get__ 'inErrorSupportPhrase'

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
        console.log "name: #{name}"
        @vero.createUserAndTrackEvent.args[0][3].should.be.eql paymentEvents[name]

      it "eventData" , ->
        @vero.createUserAndTrackEvent.args[0][4].should.be.eql
          in_error_support_phrase: subject.__get__ 'inErrorSupportPhrase'
