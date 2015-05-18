Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/http.request.validators.catchValidationRejection()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve to any value its subValidation resolves', () ->
    [
      expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: validators.integer())(param, '123')).then (value) ->
        value.should.equal(123)
      expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: validators.string(forceUpperCase: true))(param, 'abc')).then (value) ->
        value.should.equal('ABC')
      expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: [validators.defaults(defaultValue: '123'), validators.integer()])(param, null)).then (value) ->
        value.should.equal(123)
    ]

  promiseIt 'should resolve to defaultValue if its subValidation rejects with a DataValidationError', () ->
    [
      expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: validators.integer(max: 100))(param, '123')).then (value) ->
        value.should.equal(42)
      expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: validators.string(maxLength: 5))(param, 'abcdef')).then (value) ->
        value.should.equal(42)
      expectResolve(validators.catchValidationRejection(defaultValue: 42, subValidation: [validators.defaults(defaultValue: 'abc'), validators.integer()])(param, null)).then (value) ->
        value.should.equal(42)
    ]

  promiseIt 'should reject and pass through the reason if its subValidation rejects with anything other than a DataValidationError', () ->
    error = new Error("tada")
    expectReject(validators.catchValidationRejection(defaultValue: 42, subValidation: (param, value) -> throw error)(param, '123')).then (err) ->
      err.should.equal(error)
