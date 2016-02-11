Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.fips()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve to codes for counties that match the text exactly', () ->
    [
      expectResolve(validators.fips()(param, stateCode: 'DE', county: 'New Castle')).then (value) ->
        value.should.equal('10003')
      expectResolve(validators.fips()(param, stateCode: 'FL', county: 'Miami-Dade')).then (value) ->
        value.should.equal('12086')
      expectResolve(validators.fips()(param, stateCode: 'MN', county: 'St Louis')).then (value) ->
        value.should.equal('27137')
      expectResolve(validators.fips()(param, stateCode: 'WY', county: 'Sweetwater')).then (value) ->
        value.should.equal('56037')
    ]

  promiseIt 'should resolve to codes for counties that match the text ignoring capitalization, spaces, and punctuation', () ->
    [
      expectResolve(validators.fips()(param, stateCode: 'DE', county: 'newcastle')).then (value) ->
        value.should.equal('10003')
      expectResolve(validators.fips()(param, stateCode: 'FL', county: 'Miami Dade')).then (value) ->
        value.should.equal('12086')
      expectResolve(validators.fips()(param, stateCode: 'MN', county: 'st. louis')).then (value) ->
        value.should.equal('27137')
      expectResolve(validators.fips()(param, stateCode: 'WY', county: 'Sweet Water')).then (value) ->
        value.should.equal('56037')
    ]

  promiseIt 'should resolve resolve to codes for counties that almost match the text', () ->
    [
      expectResolve(validators.fips()(param, stateCode: 'DE', county: 'New Casle')).then (value) ->
        value.should.equal('10003')
      expectResolve(validators.fips()(param, stateCode: 'FL', county: 'Miami-Daed')).then (value) ->
        value.should.equal('12086')
      expectResolve(validators.fips()(param, stateCode: 'MN', county: 'Saint Louis')).then (value) ->
        value.should.equal('27137')
      expectResolve(validators.fips()(param, stateCode: 'WY', county: 'Sweet Waiter')).then (value) ->
        value.should.equal('56037')
    ]

  promiseIt 'should resolve to a given raw code if no state or county are provided', () ->
    [
      expectResolve(validators.fips()(param, "10000")).then (value) ->
        value.should.equal('10000')

    ]

  promiseIt 'should reject empty values', () ->
    [
      expectReject(validators.fips()(param, stateCode: 'DE', county: ''), DataValidationError)
      expectReject(validators.fips()(param, stateCode: 'DE', county: null), DataValidationError)
      expectReject(validators.fips()(param, stateCode: 'DE', county: undefined), DataValidationError)
    ]

  promiseIt 'should reject counties that have no resemblance to a real one in that state', () ->
    [
      expectReject(validators.fips()(param, stateCode: 'DE', county: 'Fake County'), DataValidationError)
    ]

  promiseIt 'should reject even close matches if a high threshold is given', () ->
    [
      expectReject(validators.fips(minSimilarity: 0.9)(param, stateCode: 'DE', county: 'New Casle'), DataValidationError)
    ]

  promiseIt 'should reject with no input values', () ->
    [
      expectReject(validators.fips()(param), DataValidationError)
      expectReject(validators.fips()(param, ''), DataValidationError)
    ]


