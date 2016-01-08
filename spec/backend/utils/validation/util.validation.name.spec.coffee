basePath = require '../../basePath'
expect = require('chai').expect
colorWrap = require 'color-wrap'
colorWrap(console)

{validators} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject} = require('../../../specUtils/promiseUtils')
subject = validators.name
param = 'fake'


describe 'utils/validation.validators.object()'.ns().ns('Backend'), ->

  it 'should resolve basic object', () ->
    testObj =
      first: 'John'
      last: 'Travolta'

    expectResolve(subject()(param, testObj)).then (value) ->
      value.should.equal("#{testObj.first} #{testObj.last}")
