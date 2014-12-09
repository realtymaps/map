Promise = require 'bluebird'
basePath = require '../basePath'

requestUtil = require "#{basePath}/utils/util.http.request"
validators = requestUtil.query.validators
validateAndTransform = requestUtil.query.validateAndTransform
ParamValidationError = requestUtil.query.ParamValidationError

promiseUtils = require('../../specUtils/promiseUtils')
expectResolve = promiseUtils.expectResolve
expectReject = promiseUtils.expectReject
promiseIt = promiseUtils.promiseIt


describe 'utils/http.request'.ourNs().ourNs('Backend'), ->

  describe 'validateAndTransform()', () ->

    promiseIt 'should transform all parameters that have transforms, and pass others through unchanged', () ->
      [
        expectResolve(validateAndTransform {a: 'abc', b: '5.2'}, {a: validators.string(forceUpperCase: true), b: validators.float()}).then (values) ->
          values.should.eql({a: 'ABC', b: 5.2})
        expectResolve(validateAndTransform {a: 'abc', b: '5.2'}, {}).then (values) ->
          values.should.eql({a: 'abc', b: '5.2'})
      ]

    promiseIt 'should reject if any parameters fail subValidation', () ->
      expectReject(validateAndTransform({a: 'abc', b: '5.2'}, {a: validators.string(forceUpperCase: true), b: validators.float(max: 5.1)}), ParamValidationError)

    promiseIt 'should reject when any required parameter is not present, and otherwise resolve', () ->
      [
        expectResolve(validateAndTransform {a: '', b: '0'}, {}, {a: true, b: true})
        expectReject(validateAndTransform({a: '', b: '0'}, {}, {c: true}), ParamValidationError)
      ]

    promiseIt 'should perform iterative validation when a validator is an array', () ->
      [
        expectResolve(validateAndTransform {a: null}, {a: [validators.defaults(defaultValue: '123'), validators.integer()]}).then (value) ->
          value.should.eql({a: 123})
        expectReject(validateAndTransform({a: null}, {a: [validators.defaults(defaultValue: '123'), validators.integer(max: 100)]}), ParamValidationError)
      ]
  
  describe 'validators', ->
    param = 'fake'

    describe 'defaults()', ->

      promiseIt 'should replace undefined and null values with the defaultValue, resolving any other value as-is', () ->
        options = defaultValue: 42
        [
          expectResolve(validators.defaults(options)(param, '123')).then (value) ->
            value.should.equal('123')
          expectResolve(validators.defaults(options)(param, 123)).then (value) ->
            value.should.equal(123)
          expectResolve(validators.defaults(options)(param, false)).then (value) ->
            value.should.equal(false)
          expectResolve(validators.defaults(options)(param, [5, true, 'a', {b:3}])).then (value) ->
            value.should.eql([5, true, 'a', {b:3}])
          expectResolve(validators.defaults(options)(param, undefined)).then (value) ->
            value.should.equal(42)
          expectResolve(validators.defaults(options)(param, null)).then (value) ->
            value.should.equal(42)
        ]

      promiseIt 'should repalce any value in the passed "test" array with the defaultValue, resolving any other value as-is', () ->
        options =
          defaultValue: 42
          test: [5, 'abc', null]
        [
          expectResolve(validators.defaults(options)(param, '123')).then (value) ->
            value.should.equal('123')
          expectResolve(validators.defaults(options)(param, 'abc')).then (value) ->
            value.should.equal(42)
          expectResolve(validators.defaults(options)(param, 123)).then (value) ->
            value.should.equal(123)
          expectResolve(validators.defaults(options)(param, 5)).then (value) ->
            value.should.equal(42)
          expectResolve(validators.defaults(options)(param, false)).then (value) ->
            value.should.equal(false)
          expectResolve(validators.defaults(options)(param, [5, true, 'a', {b:3}])).then (value) ->
            value.should.eql([5, true, 'a', {b:3}])
          # there is no undefined in the array, so it no longer gets replaced
          expectResolve(validators.defaults(options)(param, undefined)).then (value) ->
            (value == undefined).should.be.true
          # however we did include a null value
          expectResolve(validators.defaults(options)(param, null)).then (value) ->
            value.should.equal(42)
        ]

      promiseIt 'should repalce any value that yields truthy from the passed "test" function with the defaultValue, resolving any other value as-is', () ->
        options =
          defaultValue: 42
          test: (value) -> value > 100
        [
          expectResolve(validators.defaults(options)(param, '123')).then (value) ->
            value.should.equal(42)
          expectResolve(validators.defaults(options)(param, 'abc')).then (value) ->
            value.should.equal('abc')
          expectResolve(validators.defaults(options)(param, 123)).then (value) ->
            value.should.equal(42)
          expectResolve(validators.defaults(options)(param, 5)).then (value) ->
            value.should.equal(5)
          expectResolve(validators.defaults(options)(param, false)).then (value) ->
            value.should.equal(false)
          expectResolve(validators.defaults(options)(param, [5, true, 'a', {b:3}])).then (value) ->
            value.should.eql([5, true, 'a', {b:3}])
          expectResolve(validators.defaults(options)(param, undefined)).then (value) ->
            (value == undefined).should.be.true
          expectResolve(validators.defaults(options)(param, null)).then (value) ->
            (value == null).should.be.true
        ]

    describe 'integer()', ->

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

    describe 'float()', ->

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

      promiseIt 'should reject strings that do not represent numbers', () ->
        [
          expectReject(validators.float()(param, ''), ParamValidationError)
          expectReject(validators.float()(param, '12.3abc'), ParamValidationError)
        ]

      promiseIt 'should obey the min and max', () ->
        [
          expectReject(validators.float(min: 4.2)(param, '4.1'), ParamValidationError)
          expectReject(validators.float(max: 6)(param, '6.1'), ParamValidationError)
          expectResolve(validators.float(min: 4.1, max: 4.6)(param, '4.3'))
          expectResolve(validators.float(min: 4.1, max: 4.6)(param, '4.1'))
          expectResolve(validators.float(min: 4.1, max: 4.6)(param, '4.6'))
        ]

    describe 'string()', ->
      
      promiseIt 'should resolve strings', () ->
        [
          expectResolve(validators.string()(param, '5')).then (value) ->
            value.should.equal('5')
          expectResolve(validators.string()(param, '')).then (value) ->
            value.should.equal('')
        ]

      promiseIt 'should reject non-strings', () ->
        [
          expectReject(validators.string()(param, 5), ParamValidationError)
          expectReject(validators.string()(param, {'a': '5'}), ParamValidationError)
          expectReject(validators.string()(param, ['5']), ParamValidationError)
        ]
      
      promiseIt 'should obey the minLength and maxLength', () ->
        [
          expectReject(validators.string(minLength: 4)(param, 'abc'), ParamValidationError)
          expectReject(validators.string(maxLength: 6)(param, 'abcdefg'), ParamValidationError)
          expectResolve(validators.string(minLength: 4, maxLength: 6)(param, 'abcde'))
          expectResolve(validators.string(minLength: 4, maxLength: 6)(param, 'abcd'))
          expectResolve(validators.string(minLength: 4, maxLength: 6)(param, 'abcdef'))
        ]

      promiseIt 'should obey the regex', () ->
        [
          expectReject(validators.string(regex: /^abc$/)(param, 'abcd'), ParamValidationError)
          expectReject(validators.string(regex: '^abc$')(param, 'abcd'), ParamValidationError)
          expectResolve(validators.string(regex: /^aBc/i)(param, 'abcd'))
          expectResolve(validators.string(regex: '^abc')(param, 'abcd'))
        ]

      promiseIt 'should transform string to lowercase or uppercase when configured', () ->
        [
          expectResolve(validators.string(forceLowerCase: true)(param, 'ABCdef')).then (value) ->
            value.should.equal('abcdef')
          expectResolve(validators.string(forceUpperCase: true)(param, 'ABCdef')).then (value) ->
            value.should.equal('ABCDEF')
        ]

    describe 'choice()', ->
      
      promiseIt 'should resolve or reject based on strict equality to any value found in the choices array when no equalsTester is provided', () ->
        [
          expectResolve(validators.choice(choices: ['abc', 5, '10', true])(param, 5))
          expectReject(validators.choice(choices: ['abc', 5, '10', true])(param, 'xxx'), ParamValidationError)
          expectReject(validators.choice(choices: ['abc', 5, '10', true])(param, 10), ParamValidationError)
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
          expectReject(validators.choice(choices: choices, equalsTester: equalsTester)(param, 77), ParamValidationError)
          expectReject(validators.choice(choices: choices, equalsTester: equalsTester)(param, b), ParamValidationError)
        ]

    describe 'array()', ->

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
    
    describe 'catchValidationRejection()', () ->

      promiseIt 'should resolve to any value its subValidation resolves', () ->
        [
          expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: validators.integer())(param, '123')).then (value) ->
            value.should.equal(123)
          expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: validators.string(forceUpperCase: true))(param, 'abc')).then (value) ->
            value.should.equal('ABC')
          expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: [validators.defaults(defaultValue: '123'), validators.integer()])(param, null)).then (value) ->
            value.should.equal(123)
        ]

      promiseIt 'should resolve to defaultValue if its subValidation rejects with a ParamValidationError', () ->
        [
          expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: validators.integer(max: 100))(param, '123')).then (value) ->
            value.should.equal(42)
          expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: validators.string(maxLength: 5))(param, 'abcdef')).then (value) ->
            value.should.equal(42)
          expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: [validators.defaults(defaultValue: 'abc'), validators.integer()])(param, null)).then (value) ->
            value.should.equal(42)
        ]

      promiseIt 'should reject and pass through the reason if its subValidation rejects with anything other than a ParamValidationError', () ->
        error = new Error("tada")
        expectReject(validators.catchValidationRejection(defaultValue: 42, subValidation: (param, value) -> throw error)(param, '123')).then (err) ->
          err.should.equal(error)
