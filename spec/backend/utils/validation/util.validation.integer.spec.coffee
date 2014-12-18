Promise = require 'bluebird'
basePath = require '../../basePath'

requestUtil = require "#{basePath}/utils/util.http.request"
validators = requestUtil.query.validators
ParamValidationError = requestUtil.query.ParamValidationError

promiseUtils = require('../../../specUtils/promiseUtils')
expectResolve = promiseUtils.expectResolve
expectReject = promiseUtils.expectReject
promiseIt = promiseUtils.promiseIt

describe 'utils/http.request.validators.integer()'.ourNs().ourNs('Backend'), ->
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

  promiseIt 'should reject strings that do not represent integers', () ->
    [
      expectReject(validators.integer()(param, ''), ParamValidationError)
      expectReject(validators.integer()(param, '123abc'), ParamValidationError)
      expectReject(validators.integer()(param, '123.123'), ParamValidationError)
      expectReject(validators.integer()(param, '1.7777E3'), ParamValidationError)
    ]

  promiseIt 'should reject obey the min and max', () ->
    [
      expectReject(validators.integer(min: 4)(param, '1'), ParamValidationError)
      expectReject(validators.integer(max: 6)(param, '10'), ParamValidationError)
      expectResolve(validators.integer(min: 4, max: 6)(param, '5'))
      expectResolve(validators.integer(min: 4, max: 6)(param, '4'))
      expectResolve(validators.integer(min: 4, max: 6)(param, '6'))
    ]