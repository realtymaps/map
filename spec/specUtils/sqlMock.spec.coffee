subject = require './sqlMock'
require 'should'
{expect, assert} = require 'chai'
instance = null

describe "SqlMock", ->
  it 'exists', ->
    subject.should.be.ok

  describe "SqlMock.Instance", ->
    beforeEach ->
      instance = new subject('user', 'drawnShapes')

    it 'select all', ->
      instance.toString().should.be.eql 'select * from "user_drawn_shapes"'

    it 'where', ->
      instance
      .where id: 1
      .toString().should.be.eql """
        select * from "user_drawn_shapes"
         where "id" = '1'
      """.replace(/\n/g,'')

    it 'orWhere', ->
      instance
      .where id: 1
      .orWhere id: 2
      .toString().should.be.eql """
        select * from "user_drawn_shapes"
         where "id" = '1' or "id" = '2'
      """.replace(/\n/g,'')
