{basePath} = require '../../globalSetup'
expect = require('chai').expect
colorWrap = require 'color-wrap'
colorWrap(console)

{validators} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject} = require('../../../specUtils/promiseUtils')
subject = validators.name
param = 'fake'


describe 'utils/validation.validators.object()'.ns().ns('Backend'), ->

  it 'should work with just first and last', () ->
    testObj =
      first: 'John'
      last: 'Travolta'

    expectResolve(subject()(param, testObj)).then (value) ->
      value.should.equal("John Travolta")

  it 'should include middle if given', () ->
    testObj =
      first: 'John'
      middle: 'Wilkes'
      last: 'Booth'

    expectResolve(subject()(param, testObj)).then (value) ->
      value.should.equal("John Wilkes Booth")

  it 'should just use full if given, even if other parts are available', () ->
    testObj =
      full: 'Madonna'
      middle: 'Louise'
      last: 'Ciccone'
      full: 'Madonna'

    expectResolve(subject()(param, testObj)).then (value) ->
      value.should.equal("Madonna")
