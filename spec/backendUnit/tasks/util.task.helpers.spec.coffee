require('chai').should()
sinon = require 'sinon'
{basePath} = require '../globalSetup'
taskHelpers = require "#{basePath}/tasks/util.task.helpers"
stripeErrors = require "#{basePath}/utils/errors/util.errors.stripe"
Promise = require 'bluebird'
subject = null

describe 'SubtaskHandlerThirdparty', ->
  beforeEach ->
    subject = taskHelpers.SubtaskHandlerThirdparty

  describe 'compose', ->
    beforeEach ->
      @composed = subject.compose
        thirdPartyService: sinon.stub()
        removalService: sinon.stub()
        updateService: sinon.stub()
        invalidRequestRegex: /nope/
        invalidRequestErrorType: 'MockErrorType'
        errorHandler: stripeErrors.handler

    describe 'has SubtaskHandlerThirdparty', ->
      describe 'thirdPartyService', ->
        it 'exists', ->
          @composed.thirdPartyService.should.be.a 'function'
          @composed.thirdPartyService.called.should.be.false

        describe 'success', ->
          beforeEach ->
            @composed.thirdPartyService.returns(Promise.resolve())
            @composed.handle data: {}

          it 'called', ->
            @composed.thirdPartyService.called.should.be.true

        describe 'fail', ->
          describe 'default', ->
            beforeEach ->
              e = new Error 'hmm'
              e.type = 'crap'

              @composed.thirdPartyService.returns(Promise.reject(e))
              @composed.handle
                data:
                  errors: []

            it 'thirdPartyService called', ->
              @composed.thirdPartyService.called.should.be.true

            it 'updateService called', ->
              @composed.updateService.called.should.be.true

            it 'removalService not called', ->
              @composed.removalService.called.should.be.false

          describe 'invalidRequestErrorType', ->
            beforeEach ->
              e = new Error 'nope'
              e.type = 'MockErrorType'

              @composed.thirdPartyService.returns(Promise.reject(e))
              @subtask =
                data:
                  errors: []
              @composed.handle @subtask

            it 'thirdPartyService called', ->
              @composed.thirdPartyService.called.should.be.true
              @subtask.data.errors.length.should.be.equal 1

            it 'updateService called', ->
              @composed.updateService.called.should.be.false

            it 'removalService called', ->
              @composed.removalService.called.should.be.true
