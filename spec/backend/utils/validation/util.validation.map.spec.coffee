Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.map()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve or reject based on strict equality to any value found in the map map when no equalsTester is provided', () ->
    [
      expectResolve(validators.map(map: {abc: 'abc', '5': 5, '10': 10, x: 10})(param, '5')).then (value) ->
        value.should.equal(5)
      expectReject(validators.map(map: {abc: 'abc', '5': 5, '10': 10, x: 10})(param, 'xxx'), DataValidationError)
      expectReject(validators.map(map: {abc: 'abc', '5': 5, '10': 10, x: 10})(param, 10), DataValidationError)
      expectResolve(validators.map(map: {abc: 'abc', '5': 5, '10': 10, x: 10})(param, x), DataValidationError).then (value) ->
        value.should.equal(10)
    ]
