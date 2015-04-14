Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"

promiseUtils = require('../../../specUtils/promiseUtils')
expectResolve = promiseUtils.expectResolve
expectReject = promiseUtils.expectReject
promiseIt = promiseUtils.promiseIt

describe 'utils/http.request.validators.choice()'.ourNs().ourNs('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve or reject based on strict equality to any value found in the choices array when no equalsTester is provided', () ->
    [
      expectResolve(validators.choice(choices: ['abc', 5, '10', true])(param, 5))
      expectReject(validators.choice(choices: ['abc', 5, '10', true])(param, 'xxx'), DataValidationError)
      expectReject(validators.choice(choices: ['abc', 5, '10', true])(param, 10), DataValidationError)
    ]

  promiseIt 'should resolve or reject based on equalsTester when provided, and transform to the matching choice', () ->
    a = {key:10,value:"a"}
    b = {key:25,value:"b"}
    c = {key:23,value:"c"}
    choices = [a,b,c]
    equalsTester = (id, obj) -> obj.key == id
    [
      expectResolve(validators.choice(choices: choices, equalsTester: equalsTester)(param, 25)).then (value) ->
        value.should.equal(b)
      expectReject(validators.choice(choices: choices, equalsTester: equalsTester)(param, 77), DataValidationError)
      expectReject(validators.choice(choices: choices, equalsTester: equalsTester)(param, b), DataValidationError)
    ]
