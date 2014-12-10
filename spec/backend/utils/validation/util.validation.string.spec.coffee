Promise = require 'bluebird'
basePath = require '../../basePath'

requestUtil = require "#{basePath}/utils/util.http.request"
validators = requestUtil.query.validators
ParamValidationError = requestUtil.query.ParamValidationError

promiseUtils = require('../../../specUtils/promiseUtils')
expectResolve = promiseUtils.expectResolve
expectReject = promiseUtils.expectReject
promiseIt = promiseUtils.promiseIt

describe 'utils/http.request.validators.string()'.ourNs().ourNs('Backend'), ->
  param = 'fake'

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

  promiseIt 'should obey regex test', () ->
    [
      expectReject(validators.string(regex: /^abc$/)(param, 'abcd'), ParamValidationError)
      expectReject(validators.string(regex: '^abc$')(param, 'abcd'), ParamValidationError)
      expectResolve(validators.string(regex: /^aBc/i)(param, 'abcd'))
      expectResolve(validators.string(regex: '^abc')(param, 'abcd'))
    ]
  
  promiseIt 'should transform the string via find/replace when configured', () ->
    [
      expectResolve(validators.string(replace: ["[a]", ""])(param, "[a]bc-[A]BC-[a]bc")).then (value) ->
        value.should.equal("bc-[A]BC-[a]bc")
      expectResolve(validators.string(replace: [/\[a\]/g, ""])(param, "[a]bc-[A]BC-[a]bc")).then (value) ->
        value.should.equal("bc-[A]BC-bc")
      expectResolve(validators.string(replace: [/\[a\]/gi, ""])(param, "[a]bc-[A]BC-[a]bc")).then (value) ->
        value.should.equal("bc-BC-bc")
      expectResolve(validators.string(replace: [/^[^\d]*(\d+).*$/, "$1.0$1"])(param, "abc-123-def-456")).then (value) ->
        value.should.equal("123.0123")
      expectResolve(validators.string(replace: [/\[(z+)\]/i, "$1$1"])(param, "[zz]-[Z]-[z]")).then (value) ->
        value.should.equal("zzzz-[Z]-[z]")
      expectResolve(validators.string(replace: [/\[(z+)\]/ig, "$1$1"])(param, "[zz]-[Z]-[z]")).then (value) ->
        value.should.equal("zzzz-ZZ-zz")
    ]

  promiseIt 'should transform string to lowercase or uppercase when configured', () ->
    [
      expectResolve(validators.string(forceLowerCase: true)(param, 'ABCdef')).then (value) ->
        value.should.equal('abcdef')
      expectResolve(validators.string(forceUpperCase: true)(param, 'ABCdef')).then (value) ->
        value.should.equal('ABCDEF')
    ]
