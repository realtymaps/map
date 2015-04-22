Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"

promiseUtils = require('../../../specUtils/promiseUtils')
expectResolve = promiseUtils.expectResolve
expectReject = promiseUtils.expectReject
promiseIt = promiseUtils.promiseIt

describe 'utils/http.request.validators.float()'.ourNs().ourNs('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve strings that represent integers or decimals', () ->
    [
      expectResolve(validators.float()(param, '123')).then (value) ->
        value.should.equal(123)
      expectResolve(validators.float()(param, '-123')).then (value) ->
        value.should.equal(-123)
      expectResolve(validators.float()(param, '1.7E3')).then (value) ->
        value.should.equal(1700)
      expectResolve(validators.float()(param, '123.456')).then (value) ->
        value.should.equal(123.456)
      expectResolve(validators.float()(param, '1.777E2')).then (value) ->
        value.should.equal(177.7)
    ]

  promiseIt 'should resolve actual integers or decimals', () ->
    [
      expectResolve(validators.float()(param, 234)).then (value) ->
        value.should.equal(234)
      expectResolve(validators.float()(param, 234.56)).then (value) ->
        value.should.equal(234.56)
      expectResolve(validators.float()(param, 1.789e2)).then (value) ->
        value.should.equal(178.9)
    ]

  promiseIt 'should nullify empty values', () ->
    [
      expectResolve(validators.float()(param, '')).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.float()(param, null)).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.float()(param, undefined)).then (value) ->
        (value == null).should.be.true
    ]
    
  promiseIt 'should reject strings that do not represent numbers', () ->
    [
      expectReject(validators.float()(param, '12.3abc'), DataValidationError)
    ]

  promiseIt 'should obey the min and max', () ->
    [
      expectReject(validators.float(min: 4.2)(param, '4.1'), DataValidationError)
      expectReject(validators.float(max: 6)(param, '6.1'), DataValidationError)
      expectResolve(validators.float(min: 4.1, max: 4.6)(param, '4.3'))
      expectResolve(validators.float(min: 4.1, max: 4.6)(param, '4.1'))
      expectResolve(validators.float(min: 4.1, max: 4.6)(param, '4.6'))
    ]
