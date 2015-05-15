Promise = require 'bluebird'
basePath = require '../basePath'


{validators, validateAndTransform, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../specUtils/promiseUtils')


describe 'utils/validation.validateAndTransform()'.ns().ns('Backend'), ->

  promiseIt "should transform all parameters that have transforms, and omit parameters that don't", () ->
    [
      expectResolve validateAndTransform {a: 'abc', b: '5.2'},
        a: validators.string(forceUpperCase: true)
        b: validators.float()
      .then (values) ->
        values.should.eql({a: 'ABC', b: 5.2})
      expectResolve(validateAndTransform {a: 'abc', b: '5.2'}, {})
      .then (values) ->
        values.should.eql({})
    ]

  promiseIt 'should reject if any parameters fail validation', () ->
    expectReject validateAndTransform {a: 'abc', b: '5.2'},
      a: validators.string(forceUpperCase: true)
      b: validators.float(max: 5.1)
    , DataValidationError

  promiseIt 'should reject if a required parameter is undefined', () ->
    [
      expectResolve validateAndTransform {},
        a: validators.noop
        c: validators.defaults(defaultValue: 1)
        d: validators.defaults(defaultValue: null)
      .then (value) ->
        value.should.eql({a: undefined, c: 1, d: null})
      expectReject(validateAndTransform({}, {a: required: true}), DataValidationError)
    ]

  promiseIt 'should perform iterative validation when a validator is an array', () ->
    [
      expectResolve validateAndTransform {a: null},
        a: [validators.defaults(defaultValue: '123'), validators.integer()]
      .then (value) ->
        value.should.eql({a: 123})
      expectReject validateAndTransform {a: null},
        a: [validators.defaults(defaultValue: '123'), validators.integer(max: 100)]
      , DataValidationError
      # even nested arrays
      expectResolve validateAndTransform {a: null},
        a: [
          [validators.defaults(defaultValue: 'abc123def456'), validators.string(replace: [/^[^\d]*(\d+).*$/, "$1.0$1"])]
          validators.float()
        ]
      .then (value) ->
        value.should.eql({a: 123.0123})
    ]

  promiseIt 'should use the input to get data source key', () ->
    [
      expectResolve(validateAndTransform {a: 123}, {b: input: 'a'})
      .then (value) ->
        value.should.eql({b: 123})
    ]

  promiseIt 'should build an array of source values if input is an array', () ->
    [
      expectResolve validateAndTransform {a: "1", f: "3", q: "2"},
        z:
          input: ["q", "f", "a"]
          transform: validators.array(subValidation: validators.integer())
      .then (value) ->
        value.should.eql(z: [2, 3, 1])
    ]
