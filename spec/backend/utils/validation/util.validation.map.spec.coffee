Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.map()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve or reject based on toString() equality to any value found in the map map when no equalsTester is provided', () ->
    [
      expectResolve(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1})(param, '5')).then (value) ->
        value.should.equal(10)
      expectReject(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1})(param, 'xxx'), DataValidationError)
      expectResolve(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1})(param, 10)).then (value) ->
        value.should.equal(999)
      expectResolve(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1})(param, 'x')).then (value) ->
        value.should.equal(1)
    ]
