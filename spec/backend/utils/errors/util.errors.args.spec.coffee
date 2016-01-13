require 'should'
# expect = require 'expect'
basePath = require '../../basePath'
subject = require "#{basePath}/utils/errors/util.errors.args"

describe 'utils.errors.args', ->

  it 'exists', ->
    subject.should.be.ok

  describe 'onMissingArgsFail', ->

    beforeEach ->
      @testObj =
        field1: 1
        field2: 0 #can handle falsy
        field3: false #can handle falsy

    it 'passes on all required field existence', ->
      {field1, field2} = @testObj

      subject.onMissingArgsFail
        field1: val: field1, required: true
        field2: val: field2, required: true
        field3: val: field2, required: true

    it 'fails on missing required field', ->
      {field1} = @testObj

      (->
        subject.onMissingArgsFail
          field1: val: field1, required: true
          field2: val: null, required: true
      ).should.throw()
