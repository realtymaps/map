require('chai').should()
sinon = require 'sinon'
Promise = require 'bluebird'
{basePath, commonPath} = require '../../../globalSetup'
rewire = require 'rewire'
subject = require "#{basePath}/services/email/vero/service.email.impl.vero.events"
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

    @authUser =
      id: 1
      first_name: "Bo"
      last_name: "Jackson"
      email: ".nows@gmail.com"
      email_validation_hash: "radarIsJammed"
      cancel_email_hash: "terminated"

    @inErrorSupportPhrase = subject(@vero).inErrorSupportPhrase


  describe "subscriptionSignUp", ->

    beforeEach ->
      @promise = subject(@vero).subscriptionSignUp(@authUser)

    it "passes sanity check", ->
      @promise
      @vero.createUserAndTrackEvent.called.should.be.ok

    it "has appropriate vero API arguments", ->
      @vero.createUserAndTrackEvent.args[0][0].should.be.eql "#{process.env.RMAPS_MAP_INSTANCE_NAME}_development_#{@authUser.id}"      
      @vero.createUserAndTrackEvent.args[0][1].should.be.eql @authUser.email
      @vero.createUserAndTrackEvent.args[0][2].should.be.eql
        first_name: @authUser.first_name
        last_name: @authUser.last_name
      @vero.createUserAndTrackEvent.args[0][3].should.be.eql paymentEvents.customerSubscriptionCreated
      @vero.createUserAndTrackEvent.args[0][4].should.be.eql
        verify_url: routeHelpers.clsFullUrl(emailRoutes.verify.replace(":hash", @authUser.email_validation_hash))
        in_error_support_phrase: @inErrorSupportPhrase


  describe "subscriptionTrialEnding", ->

    beforeEach ->
      @promise = subject(@vero).subscriptionTrialEnding(@authUser)

    it "passes sanity check", ->
      @promise
      @vero.createUserAndTrackEvent.called.should.be.ok

    it "has appropriate vero API arguments", ->
      @vero.createUserAndTrackEvent.args[0][0].should.be.eql "#{process.env.RMAPS_MAP_INSTANCE_NAME}_development_#{@authUser.id}"
      @vero.createUserAndTrackEvent.args[0][1].should.be.eql @authUser.email
      @vero.createUserAndTrackEvent.args[0][2].should.be.eql
        first_name: @authUser.first_name
        last_name: @authUser.last_name
      @vero.createUserAndTrackEvent.args[0][3].should.be.eql paymentEvents.customerSubscriptionTrialWillEnd
      @vero.createUserAndTrackEvent.args[0][4].should.be.eql
        cancel_plan_url: routeHelpers.clsFullUrl emailRoutes.cancelPlan.replace(":cancelPlan", @authUser.cancel_email_hash)
        in_error_support_phrase: @inErrorSupportPhrase


  [
    'subscriptionVerified'
    'subscriptionUpdated'
  ].forEach (testName) ->
    describe testName, ->

      beforeEach ->
        @promise = subject(@vero)[testName](@authUser)

      it "passes sanity check", ->
        @promise
        @vero.createUserAndTrackEvent.called.should.be.ok

      it "has appropriate vero API arguments", ->
        @vero.createUserAndTrackEvent.args[0][0].should.be.eql "#{process.env.RMAPS_MAP_INSTANCE_NAME}_development_#{@authUser.id}"
        @vero.createUserAndTrackEvent.args[0][1].should.be.eql @authUser.email
        @vero.createUserAndTrackEvent.args[0][2].should.be.eql
          first_name: @authUser.first_name
          last_name: @authUser.last_name

        name = 'customer' + Case.pascal testName
        event = paymentEvents[name] || paymentEvents[testName]
        @vero.createUserAndTrackEvent.args[0][3].should.be.eql event
        @vero.createUserAndTrackEvent.args[0][4].should.be.eql
          in_error_support_phrase: @inErrorSupportPhrase


  describe "notificationPropertiesSaved", ->
    beforeEach ->
      @promise = subject(@vero).notificationPropertiesSaved {
        authUser: @authUser
        properties: []
        notification_id: 1
      }

    it "passes sanity check", ->
      @promise
      @vero.createUserAndTrackEvent.called.should.be.ok

    it "has appropriate vero API arguments", ->
      @vero.createUserAndTrackEvent.args[0][0].should.be.eql "#{process.env.RMAPS_MAP_INSTANCE_NAME}_development_#{@authUser.id}"
      @vero.createUserAndTrackEvent.args[0][1].should.be.eql @authUser.email
      @vero.createUserAndTrackEvent.args[0][2].should.be.eql
        first_name: @authUser.first_name
        last_name: @authUser.last_name
      @vero.createUserAndTrackEvent.args[0][3].should.be.eql paymentEvents.notificationPropertiesSaved
      @vero.createUserAndTrackEvent.args[0][4].should.contain.all.keys {
        in_error_support_phrase: @inErrorSupportPhrase
        properties: []
        notification_id: 1
      }
