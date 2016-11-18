require("chai").should()
errorHandlingUtils = require '../../../../backend/utils/errors/util.error.partiallyHandledError'
rets = require 'rets-client'


describe 'util.error.partiallyHandledError', ->
  it 'exists', ->
    errorHandlingUtils.should.be.ok

  describe 'isKnexUndefined', ->

    it 'basic knex undefined is truthy', ->
      errorHandlingUtils
      .isKnexUndefined(new Error('Undefined binding(s) detected when compiling crap'))
      .should.be.ok

  describe 'isRets', ->

    it 'basic RetsError', ->
      errorHandlingUtils
      .isRets(new rets.RetsError('')) #RetsError is instance of Error
      .should.not.be.ok

    it 'basic RetsReplyError', ->
      errorHandlingUtils
      .isRets(new rets.RetsReplyError(''))
      .should.be.ok

    it 'basic RetsServerError', ->
      errorHandlingUtils
      .isRets(new rets.RetsServerError(''))
      .should.be.ok

    it 'basic RetsProcessingError', ->
      errorHandlingUtils
      .isRets(new rets.RetsProcessingError(''))
      .should.be.ok

    it 'basic RetsParamError', ->
      errorHandlingUtils
      .isRets(new rets.RetsParamError(''))
      .should.be.ok
