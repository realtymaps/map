{expect,should} =require("chai")
should()
Promise = require 'bluebird'
_ = require 'lodash'
NamedError = require '../../../../backend/utils/errors/util.error.named'

describe 'util.error.named', ->

  beforeEach ->
    @subject = NamedError

  it 'exists', ->
    @subject.should.be.ok

  describe 'throws', ->
    it 'with correct name', ->
      err = new NamedError('poop', {quiet: true}, "montezuma's revenge")
      str = err.toString()
      str.should.have.string "poop: montezuma's revenge"
      (-> throw err).should.throw(/montezuma's revenge/)
