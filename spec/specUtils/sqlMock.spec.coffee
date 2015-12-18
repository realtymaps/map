subject = require './sqlMock'
require 'should'
{expect, assert} = require 'chai'

describe "SqlMock", ->
  it 'exists', ->
    subject.should.be.ok

  describe "SqlMock.Instance", ->
    beforeEach ->
      subject = new subject('user', 'drawnShapes')

    it 'select all', ->
      subject.toString().should.be.eql 'select * from "user_drawn_shapes"'
