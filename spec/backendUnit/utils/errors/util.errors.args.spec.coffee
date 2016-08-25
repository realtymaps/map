require('chai').should()
# expect = require 'expect'
{basePath} = require '../../globalSetup'
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
        args: {field1,field2}
        required: ['field1','field2']
        quiet: true

    it 'fails on missing required field', ->
      {field1} = @testObj

      (->
        subject.onMissingArgsFail
          args: {field1,field2:null}
          required: ['field1','field2']
          quiet: true
      ).should.throw()
