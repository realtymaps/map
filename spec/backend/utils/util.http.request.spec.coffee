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


describe 'utils/http.request.validateAndTransform()'.ourNs().ourNs('Backend'), ->

  promiseIt 'should transform all parameters that have transforms, and pass others through unchanged', () ->
    [
      expectResolve(validateAndTransform {a: 'abc', b: '5.2'}, {a: validators.string(forceUpperCase: true), b: validators.float()}).then (values) ->
        values.should.eql({a: 'ABC', b: 5.2})
      expectResolve(validateAndTransform {a: 'abc', b: '5.2'}, {}).then (values) ->
        values.should.eql({a: 'abc', b: '5.2'})
    ]

  promiseIt 'should reject if any parameters fail subvalidation', () ->
    expectReject(validateAndTransform({a: 'abc', b: '5.2'}, {a: validators.string(forceUpperCase: true), b: validators.float(max: 5.1)}), ParamValidationError)

  promiseIt 'should resolve with defaults for required parameters, or reject if a default value is not given', () ->
    [
      expectResolve(validateAndTransform {a: '', b: '0'}, {}, {c: 1, d: null}).then (value) ->
        value.should.eql({a: '', b: '0', c: 1, d: null})
      expectReject(validateAndTransform({a: '', b: '0'}, {}, {c: undefined}), ParamValidationError)
    ]

  promiseIt 'should perform iterative validation when a validator is an array', () ->
    [
      expectResolve(validateAndTransform {a: null}, {a: [validators.defaults(defaultValue: '123'), validators.integer()]}).then (value) ->
        value.should.eql({a: 123})
      expectReject(validateAndTransform({a: null}, {a: [validators.defaults(defaultValue: '123'), validators.integer(max: 100)]}), ParamValidationError)
      # even nested arrays
      expectResolve(validateAndTransform {a: null}, {a: [ [validators.defaults(defaultValue: 'abc123def456'), validators.string(replace: [/^[^\d]*(\d+).*$/, "$1.0$1"])], validators.float()]}).then (value) ->
        value.should.eql({a: 123.0123})
    ]
