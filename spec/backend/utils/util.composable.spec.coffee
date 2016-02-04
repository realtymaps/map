basePath = require '../basePath'
subject = require "#{basePath}/utils/util.composable"
sinon = require 'sinon'
require("chai").should()

describe 'composable', ->
  beforeEach ->
    @composedAb = subject.compose
      a: 'a'
      aFn: sinon.stub()
    ,
      b: 'b'
      bFn: sinon.stub()

    @composedC = @composedAb.compose
      c: 'c'
      cFn: sinon.stub()
      callAll: () ->
        @aFn()
        @bFn()
        @cFn()

  describe 'composed', ->
    it 'exists on instance', ->
      @composedAb.compose.should.be.a 'function'

    it 'has a', ->
      @composedAb.a.should.be.eql 'a'
      @composedAb.aFn.should.be.a 'function'

    it 'has b', ->
      @composedAb.b.should.be.eql 'b'
      @composedAb.bFn.should.be.a 'function'

  describe 'inherited from previous composition to composedC', ->
    it 'has a', ->
      @composedC.a.should.be.eql 'a'
      @composedC.aFn.should.be.a 'function'

    it 'has b', ->
      @composedC.b.should.be.eql 'b'
      @composedC.bFn.should.be.a 'function'

    it 'has c', ->
      @composedC.c.should.be.eql 'c'
      @composedC.cFn.should.be.a 'function'

    it 'callAll', ->
      @composedC.callAll()
      @composedC.aFn.called.should.be.true
      @composedC.bFn.called.should.be.true
      @composedC.cFn.called.should.be.true
