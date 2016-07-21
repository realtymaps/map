Promise = require 'bluebird'
{basePath} = require '../../globalSetup'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.amount()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve amount strings as numeric', () ->
    [
      expectResolve(validators.amount()(param, {amount: '123'})).then (value) ->
        value.should.equal(123)
    ]

  promiseIt 'should resolve amounts as themselves', () ->
    [
      expectResolve(validators.amount()(param, {amount: 123})).then (value) ->
        value.should.equal(123)
    ]

  promiseIt 'should scale when indicated', () ->
    [
      expectResolve(validators.amount()(param, {amount: '123', scale: 'A'})).then (value) ->
        value.should.equal(123)
      expectResolve(validators.amount()(param, {amount: '123', scale: 'K'})).then (value) ->
        value.should.equal(1230)
      expectResolve(validators.amount()(param, {amount: '123', scale: 'T'})).then (value) ->
        value.should.equal(12300)
    ]
