Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/http.request.validators.pickFirst()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve to the first element of the array when there are no criteria', () ->
    [
      expectResolve(validators.pickFirst()(param, [5, 10])).then (value) ->
        value.should.equal(5)
      expectResolve(validators.pickFirst()(param, ['abc', 'defghij'])).then (value) ->
        value.should.equal('abc')
    ]

  promiseIt 'should resolve to the first non-rejecting element of the array when there are criteria', () ->
    [
      expectResolve(validators.pickFirst(criteria: validators.integer(min: 8))(param, [5, 10])).then (value) ->
        value.should.equal(10)
      expectResolve(validators.pickFirst(criteria: validators.string(minLength: 5))(param, ['abc', 'defghij'])).then (value) ->
        value.should.equal('defghij')
    ]

  promiseIt 'should nullify empty values', () ->
    [
      expectResolve(validators.pickFirst()(param, '')).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.pickFirst()(param, null)).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.pickFirst()(param, undefined)).then (value) ->
        (value == null).should.be.true
    ]

  promiseIt 'should reject non-arrays', () ->
    [
      expectReject(validators.pickFirst()(param, 'abc'), DataValidationError)
      expectReject(validators.pickFirst()(param, 5), DataValidationError)
      expectReject(validators.pickFirst()(param, {a: 1, length: 2}), DataValidationError)
      expectReject(validators.pickFirst()(param, true), DataValidationError)
    ]

  promiseIt 'should reject when all array elements reject', () ->
    [
      expectReject(validators.pickFirst(criteria: validators.integer(min: 18))(param, [5, 10]), DataValidationError)
      expectReject(validators.pickFirst(criteria: validators.string(minLength: 15))(param, ['abc', 'defghij']), DataValidationError)
    ]
