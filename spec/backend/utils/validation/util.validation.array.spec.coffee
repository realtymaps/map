Promise = require 'bluebird'
basePath = require '../../basePath'

requestUtil = require "#{basePath}/utils/util.http.request"
validators = requestUtil.query.validators
ParamValidationError = requestUtil.query.ParamValidationError

promiseUtils = require('../../../specUtils/promiseUtils')
expectResolve = promiseUtils.expectResolve
expectReject = promiseUtils.expectReject
promiseIt = promiseUtils.promiseIt

describe 'utils/http.request.validators.array()'.ourNs().ourNs('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve arrays', () ->
    [
      expectResolve(validators.array()(param, [5, 10]))
      expectResolve(validators.array()(param, ['abc', 'def']))
      expectResolve(validators.array()(param, [{a: 1}]))
      expectResolve(validators.array()(param, ['abc', 5, '10', true]))
      expectResolve(validators.array()(param, []))
    ]
  promiseIt 'should reject non-arrays', () ->
    [
      expectReject(validators.array()(param, 'abc'), ParamValidationError)
      expectReject(validators.array()(param, 5), ParamValidationError)
      expectReject(validators.array()(param, {a: 1, length: 2}), ParamValidationError)
      expectReject(validators.array()(param, true), ParamValidationError)
    ]

  promiseIt 'should obey the minLength and maxLength', () ->
    [
      expectReject(validators.array(minLength: 2)(param, ['abc']), ParamValidationError)
      expectReject(validators.array(maxLength: 4)(param, ['abc', 2, true, 4, 5]), ParamValidationError)
      expectResolve(validators.array(minLength: 2, maxLength: 4)(param, ['abc', 2, true]))
      expectResolve(validators.array(minLength: 2, maxLength: 4)(param, ['abc', 2, true, 4]))
      expectResolve(validators.array(minLength: 2, maxLength: 4)(param, ['abc', 2]))
    ]

  promiseIt 'should resolve strings when split is set', () ->
    [
      expectResolve(validators.array(split: /\s*,\s* ?/)(param, "abc, def,ghi  , \t jkl")).then (value) ->
        value.should.eql(['abc', 'def', 'ghi', 'jkl'])
      expectResolve(validators.array(split: ',')(param, "abc,def,ghi,jkl")).then (value) ->
        value.should.eql(['abc', 'def', 'ghi', 'jkl'])
      expectResolve(validators.array(split: ',')(param, "abc")).then (value) ->
        value.should.eql(['abc'])
      expectReject(validators.array(split: ',', maxLength: 3)(param, "abc,def,ghi,jkl"), ParamValidationError)
      expectReject(validators.array(split: ',', minLength: 5)(param, "abc,def,ghi,jkl"), ParamValidationError)
      expectResolve(validators.array(split: ',', minLength: 4, maxLength: 4)(param, "abc,def,ghi,jkl")).then (value) ->
        value.should.eql(['abc', 'def', 'ghi', 'jkl'])
    ]

  promiseIt 'should perform subvalidation when configured', () ->
    customIndexAwareSubvalidation = (paramName, value, index, length) ->
      if index < 2
        validators.integer()(paramName, value)
      else if index >= length-2
        validators.string(forceUpperCase: true)(paramName, value)
      else
        Promise.resolve("value #{index+1} of #{length}: #{value}")
    [
      expectResolve(validators.array(subValidation: validators.integer())(param, [1, 1, "2", "3", 5, 8])).then (value) ->
        value.should.eql([1, 1, 2, 3, 5, 8])
      expectResolve(validators.array(subValidation: validators.string(forceUpperCase: true))(param, ["abc", "def"])).then (value) ->
        value.should.eql(["ABC", "DEF"])
      expectResolve(validators.array(split: /\s*,\s* ?/, subValidation: validators.integer())(param, "1,2, 3, 4 ,5")).then (value) ->
        value.should.eql([1,2,3,4,5])
      expectReject(validators.array(split: /\s*,\s* ?/, subValidation: validators.integer())(param, "1,2, 3.4, 4 ,5"), ParamValidationError)
      expectReject(validators.array(split: /\s*,\s* ?/, subValidation: validators.integer(max: 3))(param, "1,2, 3, 4 ,5"), ParamValidationError)
      expectResolve(validators.array(subValidation: customIndexAwareSubvalidation)(param, ["1", 2, "asdf", "qwert", "zxcv"])).then (value) ->
        value.should.eql([1,2,"value 3 of 5: asdf","QWERT","ZXCV"])
    ]

  promiseIt 'can perform iterative subvalidations passed as an array', () ->
    a = {key:1,value:"a"}
    b = {key:2,value:"b"}
    c = {key:3,value:"c"}
    choices = [a,b,c]
    equalsTester = (id, obj) -> obj.key == id
    # split the string, convert each element into an integer, then use each id to find the matching object from in choices
    expectResolve(validators.array(split: ',', subValidation: [validators.integer(), validators.choice(choices: choices, equalsTester: equalsTester)])(param, "2,1,1,3")).then (value) ->
      value.should.eql([b,a,a,c])
