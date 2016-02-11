Promise = require 'bluebird'
{basePath} = require '../../globalSetup'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.array()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve arrays', () ->
    [
      expectResolve(validators.array()(param, [5, 10]))
      expectResolve(validators.array()(param, ['abc', 'def']))
      expectResolve(validators.array()(param, [{a: 1}]))
      expectResolve(validators.array()(param, ['abc', 5, '10', true]))
      expectResolve(validators.array()(param, []))
    ]

  promiseIt 'should nullify empty values', () ->
    [
      expectResolve(validators.array()(param, '')).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.array()(param, null)).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.array()(param, undefined)).then (value) ->
        (value == null).should.be.true
    ]

  promiseIt 'should reject non-arrays', () ->
    [
      expectReject(validators.array()(param, 'abc'), DataValidationError)
      expectReject(validators.array()(param, 5), DataValidationError)
      expectReject(validators.array()(param, {a: 1, length: 2}), DataValidationError)
      expectReject(validators.array()(param, true), DataValidationError)
    ]

  promiseIt 'should obey the minLength and maxLength', () ->
    [
      expectReject(validators.array(minLength: 2)(param, ['abc']), DataValidationError)
      expectReject(validators.array(maxLength: 4)(param, ['abc', 2, true, 4, 5]), DataValidationError)
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
      expectReject(validators.array(split: ',', maxLength: 3)(param, "abc,def,ghi,jkl"), DataValidationError)
      expectReject(validators.array(split: ',', minLength: 5)(param, "abc,def,ghi,jkl"), DataValidationError)
      expectResolve(validators.array(split: ',', minLength: 4, maxLength: 4)(param, "abc,def,ghi,jkl")).then (value) ->
        value.should.eql(['abc', 'def', 'ghi', 'jkl'])
    ]

  promiseIt 'should perform subvalidation on each element of array', () ->
    customIndexAwareSubvalidation = (paramName, value, index, length) ->
      if index < 2
        validators.integer()(paramName, value)
      else if index >= length-2
        validators.string(forceUpperCase: true)(paramName, value)
      else
        Promise.resolve("value #{index+1} of #{length}: #{value}")
    [
      expectResolve(validators.array(subValidateEach: validators.integer())(param, [1, 1, "2", "3", 5, 8])).then (value) ->
        value.should.eql([1, 1, 2, 3, 5, 8])
      expectResolve(validators.array(subValidateEach: validators.string(forceUpperCase: true))(param, ["abc", "def"])).then (value) ->
        value.should.eql(["ABC", "DEF"])
      expectResolve(validators.array(split: /\s*,\s* ?/, subValidateEach: validators.integer())(param, "1,2, 3, 4 ,5")).then (value) ->
        value.should.eql([1,2,3,4,5])
      expectReject(validators.array(split: /\s*,\s* ?/, subValidateEach: validators.integer())(param, "1,2, 3.4, 4 ,5"), DataValidationError)
      expectReject(validators.array(split: /\s*,\s* ?/, subValidateEach: validators.integer(max: 3))(param, "1,2, 3, 4 ,5"), DataValidationError)
      expectResolve(validators.array(subValidateEach: customIndexAwareSubvalidation)(param, ["1", 2, "asdf", "qwert", "zxcv"])).then (value) ->
        value.should.eql([1,2,"value 3 of 5: asdf","QWERT","ZXCV"])
      # similar as the above, but using subValidateSeparate instead
      arrayValidator = validators.array
        subValidateSeparate: [
          validators.integer()
          validators.integer()
          validators.string(forceLowerCase: true)
          validators.string(forceUpperCase: true)
          # there's 1 more element than there are validators, so last element will be passed through
        ]
      expectResolve(arrayValidator(param, ["1", 2, "aSDf", "aSDf", "aSDf"])).then (value) ->
        value.should.eql([1,2,"asdf","ASDF","aSDf"])
      # again, but with more validators than elements
      arrayValidator = validators.array
        subValidateSeparate: [
          validators.integer()
          validators.integer()
          [validators.defaults(defaultValue: "qwERt"), validators.string(forceLowerCase: true)]
          [validators.defaults(defaultValue: "qwERt"), validators.string(forceLowerCase: true)]
        ]
      expectResolve(arrayValidator(param, ["1", 2, "aSDf"])).then (value) ->
        value.should.eql([1,2,"asdf","qwert"])
    ]

  promiseIt 'can perform iterative subvalidations passed as an array', () ->
    a = {key:1,value:"a"}
    b = {key:2,value:"b"}
    c = {key:3,value:"c"}
    choices = [a,b,c]
    equalsTester = (id, obj) -> obj.key == id
    # split the string, convert each element into an integer, then use each id to find the matching object from in choices
    expectResolve(validators.array(split: ',', subValidateEach: [validators.integer(), validators.choice(choices: choices, equalsTester: equalsTester)])(param, "2,1,1,3")).then (value) ->
      value.should.eql([b,a,a,c])

  promiseIt 'should join elements when configured', () ->
    expectResolve(validators.array(split: ',', subValidateEach: validators.integer(), join: '_')(param, "2,1,1,3")).then (value) ->
      value.should.eql('2_1_1_3')
