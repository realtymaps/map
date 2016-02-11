Promise = require 'bluebird'
{basePath} = require '../../globalSetup'
_ = require 'lodash'
expect = require('chai').expect
colorWrap = require 'color-wrap'
colorWrap(console)

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.object()'.ns().ns('Backend'), ->
  param = 'fake'
  testObj = {}
  testObj2 = id:1
  it 'should resolve basic object', () ->
    [
      expectResolve(validators.object()(param, testObj)).then (value) ->
        value.should.equal(testObj)
      expectReject(validators.object()(param, '5'))
      expectResolve(validators.object()(param, testObj2)).then (value) ->
        value.should.equal(testObj2)
    ]

  it "isEmptyProtect should wipe whatever ''", () ->
    [
      expectResolve(validators.object(isEmptyProtect:true)(param, null)).then (value) ->
        expect(value).to.not.be.ok
      expectResolve(validators.object(isEmptyProtect:true)(param, {id:1})).then (value) ->
        _.isEmpty(value).should.be.ok
    ]

  it "isEmpty should wipe whatever ''", () ->
    [
      expectResolve(validators.object(isEmpty:true)(param, null)).then (value) ->
        expect(value).to.not.be.ok
      expectReject(validators.object(isEmpty:true)(param, {id:1}))
    ]
  describe 'subValidateSeparate', ->
    it 'should resolve basic object', () ->
      toSubVal =
          id: 1
          someStr: 'happy'

      [
        expectResolve(validators.object()(param, toSubVal)).then (value) ->
          value.should.equal(toSubVal)
        expectResolve(validators.object(
          subValidateSeparate:
            id: validators.integer()
            someStr: validators.string()
        )(param, toSubVal)).then (value) ->
          value.should.eql(toSubVal)
      ]

    it 'subValidaiton fails', () ->
      toSubVal =
          id: 1
          someStr: 'happy'

      [
        expectReject(validators.object(
          subValidateSeparate:
            id: validators.integer()
            someStr: validators.string(minLength:6)
        )(param, toSubVal))
      ]
