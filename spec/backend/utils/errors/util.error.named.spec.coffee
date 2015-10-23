require '../../../globals'
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
      phrase = "montezuma's revenge"
      err = new NamedError('poop', phrase)
      str = err.toString()
      str.should.be.equal "#{err.name}: #{phrase}"
      (-> throw err).should.throw(phrase)
