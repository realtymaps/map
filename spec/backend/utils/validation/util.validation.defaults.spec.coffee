Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.defaults()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should replace undefined, null, and '' values with the defaultValue, resolving any other value as-is', () ->
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
      expectResolve(validators.defaults(options)(param, '')).then (value) ->
        value.should.equal(42)
    ]

  promiseIt 'should replace any value in the passed "test" array with the defaultValue, resolving any other value as-is', () ->
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

  promiseIt 'should replace any value that yields truthy from the passed "test" function with the defaultValue, resolving any other value as-is', () ->
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
