Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/http.request.validators.float()'.ns().ns('Backend'), ->
  param = 'fake'

  if process.env.NODE_ENV == 'test'
    it "can't run on CircleCI because db trigram matching can't be mocked", () ->
      #noop
    return
    
  promiseIt 'should resolve to codes for counties that match the text exactly', () ->
    [
      expectResolve(validators.fips(states: ['DE'])(param, 'New Castle')).then (value) ->
        value.should.equal('10003')
      expectResolve(validators.fips(states: ['FL'])(param, 'Miami-Dade')).then (value) ->
        value.should.equal('12086')
      expectResolve(validators.fips(states: ['MN'])(param, 'St Louis')).then (value) ->
        value.should.equal('27137')
      expectResolve(validators.fips(states: ['WY'])(param, 'Sweetwater')).then (value) ->
        value.should.equal('56037')
    ]

  promiseIt 'should resolve to codes for counties that match the text ignoring capitalization, spaces, and punctuation', () ->
    [
      expectResolve(validators.fips(states: ['DE'])(param, 'newcastle')).then (value) ->
        value.should.equal('10003')
      expectResolve(validators.fips(states: ['FL'])(param, 'Miami Dade')).then (value) ->
        value.should.equal('12086')
      expectResolve(validators.fips(states: ['MN'])(param, 'st. louis')).then (value) ->
        value.should.equal('27137')
      expectResolve(validators.fips(states: ['WY'])(param, 'Sweet Water')).then (value) ->
        value.should.equal('56037')
    ]

  promiseIt 'should resolve resolve to codes for counties that almost match the text', () ->
    [
      expectResolve(validators.fips(states: ['DE'])(param, 'New Casle')).then (value) ->
        value.should.equal('10003')
      expectResolve(validators.fips(states: ['FL'])(param, 'Miami-Daed')).then (value) ->
        value.should.equal('12086')
      expectResolve(validators.fips(states: ['MN'])(param, 'Saint Louis')).then (value) ->
        value.should.equal('27137')
      expectResolve(validators.fips(states: ['WY'])(param, 'Sweet Waiter')).then (value) ->
        value.should.equal('56037')
    ]

  promiseIt 'should nullify empty values', () ->
    [
      expectResolve(validators.fips(states: ['DE'])(param, '')).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.fips(states: ['DE'])(param, null)).then (value) ->
        (value == null).should.be.true
      expectResolve(validators.fips(states: ['DE'])(param, undefined)).then (value) ->
        (value == null).should.be.true
    ]

  promiseIt 'should reject counties that have no resemblance to a real one in that state', () ->
    [
      expectReject(validators.fips(states: ['DE'])(param, 'Fake County'), DataValidationError)
    ]

  promiseIt 'should reject even close matches if a high threshold is given', () ->
    [
      expectReject(validators.fips(states: ['DE'], minSimilarity: 0.9)(param, 'New Casle'), DataValidationError)
    ]
