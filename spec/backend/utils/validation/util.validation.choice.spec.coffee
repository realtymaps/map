Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.choice()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve or reject based on strict equality to any value found in the choices array when no equalsTester is provided', () ->
    [
      expectResolve(validators.choice(choices: ['abc', 5, '10', true])(param, 5))
      expectReject(validators.choice(choices: ['abc', 5, '10', true])(param, 'xxx'), DataValidationError)
      expectReject(validators.choice(choices: ['abc', 5, '10', true])(param, 10), DataValidationError)
    ]

  promiseIt 'should resolve or reject based on strict equality to any value found in the choices map when no equalsTester is provided', () ->
    [
      expectResolve(validators.choice(choices: {abc: 'abc', '5': 5, '10': 10})(param, '5'))
      expectReject(validators.choice(choices: {abc: 'abc', '5': 5, '10': 10})(param, 'xxx'), DataValidationError)
      expectReject(validators.choice(choices: {abc: 'abc', '5': 5, '10': 10})(param, 10), DataValidationError)
    ]

  promiseIt 'should nullify empty values unless given in choices', () ->
    [
      expectResolve(validators.choice(choices: ['abc', 5, '10', true])(param, '')).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.choice(choices: ['abc', 5, '10', true, ''])(param, '')).then (value) ->
        value.should.equal('')
      expectResolve(validators.choice(choices: ['abc', 5, '10', true])(param, null)).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.choice(choices: ['abc', 5, '10', true])(param, undefined)).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.choice(choices: ['abc', 5, '10', true, undefined])(param, undefined)).then (value) ->
        (value == undefined).should.be.true
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

  promiseIt 'should resolve or reject based on equalsTester when provided, and transform to the matching choice\'s value', () ->
    choices =
      '10': 'a'
      '25': 'b'
      '23': 'c'
    equalsTester = (value, key) -> ''+value == key
    [
      expectResolve(validators.choice(choices: choices, equalsTester: equalsTester)(param, 25)).then (value) ->
        value.should.equal('b')
      expectReject(validators.choice(choices: choices, equalsTester: equalsTester)(param, 77), DataValidationError)
      expectReject(validators.choice(choices: choices, equalsTester: equalsTester)(param, 'b'), DataValidationError)
    ]
