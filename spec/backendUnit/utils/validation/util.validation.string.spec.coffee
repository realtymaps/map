Promise = require 'bluebird'
require('chai').should()
{basePath} = require '../../globalSetup'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.string()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve strings', () ->
    [
      expectResolve(validators.string()(param, '5')).then (value) ->
        value.should.equal('5')
      expectResolve(validators.string()(param, 'asdf')).then (value) ->
        value.should.equal('asdf')
    ]

  promiseIt "should nullify empty values except ''", () ->
    [
      expectResolve(validators.string()(param, '')).then (value) ->
        value.should.equal('')
      expectResolve(validators.string()(param, null)).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.string()(param, undefined)).then (value) ->
        (value == null).should.be.true
    ]

  promiseIt 'should reject non-strings', () ->
    [
      expectReject(validators.string()(param, 5), DataValidationError)
      expectReject(validators.string()(param, {'a': '5'}), DataValidationError)
      expectReject(validators.string()(param, ['5']), DataValidationError)
    ]

  promiseIt 'should obey the minLength and maxLength', () ->
    [
      expectReject(validators.string(minLength: 4)(param, 'abc'), DataValidationError)
      expectReject(validators.string(maxLength: 6)(param, 'abcdefg'), DataValidationError)
      expectResolve(validators.string(minLength: 4, maxLength: 6)(param, 'abcde'))
      expectResolve(validators.string(minLength: 4, maxLength: 6)(param, 'abcd'))
      expectResolve(validators.string(minLength: 4, maxLength: 6)(param, 'abcdef'))
    ]

  promiseIt 'should obey regex test', () ->
    [
      expectReject(validators.string(regex: /^abc$/)(param, 'abcd'), DataValidationError)
      expectReject(validators.string(regex: '^abc$')(param, 'abcd'), DataValidationError)
      expectResolve(validators.string(regex: /^aBc/i)(param, 'abcd'))
      expectResolve(validators.string(regex: '^abc')(param, 'abcd'))
    ]

  promiseIt 'should transform the string via find/replace when configured', () ->
    [
      expectResolve(validators.string(replace: ["[a]", ''])(param, "[a]bc-[A]BC-[a]bc")).then (value) ->
        value.should.equal("bc-[A]BC-[a]bc")
      expectResolve(validators.string(replace: [/\[a\]/g, ''])(param, "[a]bc-[A]BC-[a]bc")).then (value) ->
        value.should.equal("bc-[A]BC-bc")
      expectResolve(validators.string(replace: [/\[a\]/gi, ''])(param, "[a]bc-[A]BC-[a]bc")).then (value) ->
        value.should.equal("bc-BC-bc")
      expectResolve(validators.string(replace: [/^[^\d]*(\d+).*$/, "$1.0$1"])(param, "abc-123-def-456")).then (value) ->
        value.should.equal("123.0123")
      expectResolve(validators.string(replace: [/\[(z+)\]/i, "$1$1"])(param, "[zz]-[Z]-[z]")).then (value) ->
        value.should.equal("zzzz-[Z]-[z]")
      expectResolve(validators.string(replace: [/\[(z+)\]/ig, "$1$1"])(param, "[zz]-[Z]-[z]")).then (value) ->
        value.should.equal("zzzz-ZZ-zz")
    ]

  promiseIt 'should transform string case when configured', () ->
    [
      expectResolve(validators.string(forceLowerCase: true)(param, 'ABCdef')).then (value) ->
        value.should.equal('abcdef')
      expectResolve(validators.string(forceUpperCase: true)(param, 'ABCdef')).then (value) ->
        value.should.equal('ABCDEF')
      expectResolve(validators.string(forceInitCaps: true)(param, "TESTING with dash-es and a'postrophes")).then (value) ->
        value.should.equal("Testing With Dash-Es And A'Postrophes")
    ]

  promiseIt 'should pad string when configured', () ->
    [
      expectResolve(validators.string(leftPad: {target: 5, padding: '*'})(param, 'abc')).then (value) ->
        value.should.equal('**abc')
      expectResolve(validators.string(leftPad: {target: 2, padding: '*'})(param, 'abc')).then (value) ->
        value.should.equal('abc')
      expectResolve(validators.string(rightPad: {target: 6, padding: '~'})(param, 'abc')).then (value) ->
        value.should.equal('abc~~~')
      expectResolve(validators.string(rightPad: {target: 3, padding: '~'})(param, 'abc')).then (value) ->
        value.should.equal('abc')
    ]

  describe 'in', () ->
    it 'throw on bad options', () ->
      ( -> validators.string(in: {})).should.throw()

    it 'thow when not in', () ->
      expectReject(validators.string(in: ['crap', 'hmm'])(param, 'abcd'), DataValidationError)

    it 'pass when in', () ->
      expectResolve(validators.string(in: ['crap', 'abcd'])(param, 'abcd'))
