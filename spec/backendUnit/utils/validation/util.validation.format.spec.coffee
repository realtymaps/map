Promise = require 'bluebird'
{basePath} = require '../../globalSetup'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.format()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should calculate implicit decimal places and add commas for Numbers', () ->
    [
      expectResolve(validators.format(deliminate: true)(param, 10000.01)).then (value) ->
        value.should.equal("10,000.01")
      expectResolve(validators.format(deliminate: true)(param, 100000.1)).then (value) ->
        value.should.equal("100,000.1")
    ]

  promiseIt 'should prefix Numbers with "$"', () ->
    [
      expectResolve(validators.format(addDollarSign: true)(param, 1000001)).then (value) ->
        value.should.equal("$1000001")
      expectResolve(validators.format(addDollarSign: true, deliminate: true)(param, 10000.01)).then (value) ->
        value.should.equal("$10,000.01")
    ]
