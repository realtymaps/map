Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/http.request.validators.integer()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve strings that represent integers', () ->
    [
      expectResolve(validators.integer()(param, '123')).then (value) ->
        value.should.equal(123)
      expectResolve(validators.integer()(param, '-123')).then (value) ->
        value.should.equal(-123)
      expectResolve(validators.integer()(param, '1.7E3')).then (value) ->
        value.should.equal(1700)
    ]

  promiseIt 'should resolve actual integers', () ->
    [
      expectResolve(validators.integer()(param, 234)).then (value) ->
        value.should.equal(234)
      expectResolve(validators.integer()(param, 1.7e2)).then (value) ->
        value.should.equal(170)
    ]

  promiseIt 'should nullify empty values', () ->
    [
      expectResolve(validators.integer()(param, '')).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.integer()(param, null)).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.integer()(param, undefined)).then (value) ->
        (value == null).should.be.true
    ]

  promiseIt 'should reject strings that do not represent integers', () ->
    [
      expectReject(validators.integer()(param, '123abc'), DataValidationError)
      expectReject(validators.integer()(param, '123.123'), DataValidationError)
      expectReject(validators.integer()(param, '1.7777E3'), DataValidationError)
    ]

  promiseIt 'should reject obey the min and max', () ->
    [
      expectReject(validators.integer(min: 4)(param, '1'), DataValidationError)
      expectReject(validators.integer(max: 6)(param, '10'), DataValidationError)
      expectResolve(validators.integer(min: 4, max: 6)(param, '5'))
      expectResolve(validators.integer(min: 4, max: 6)(param, '4'))
      expectResolve(validators.integer(min: 4, max: 6)(param, '6'))
    ]
