require("chai").should()
errorHandlingUtils = require '../../../../backend/utils/errors/util.error.partiallyHandledError'

describe 'util.error.partiallyHandledError', ->
  it 'exists', ->
    errorHandlingUtils.should.be.ok

  describe 'isKnexUndefined', ->

    it 'basic knex undefined is truthy', ->
      errorHandlingUtils
      .isKnexUndefined(new Error('Undefined binding(s) detected when compiling crap'))
      .should.be.ok
