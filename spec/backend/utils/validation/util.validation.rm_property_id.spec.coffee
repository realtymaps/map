Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.rm_property_id()'.ns().ns('Backend'), ->
  param = 'fake'

  if process.env.CIRCLECI
    it "can't run on CircleCI because postgres-based trigram matching can't be mocked", () ->
      #noop
    return

  promiseIt 'should resolve given a stateCode & county for fips lookup, a parcelId, and default 001', () ->
    [
      expectResolve(validators.rm_property_id()(param, stateCode: 'DE', county: 'New Castle', parcelId: '10001')).then (value) ->
        value.should.equal('10003_10001_001')
    ]

  promiseIt 'should resolve given a fipsCode, an apnUnformatted, and apnSequence', () ->
    [
      expectResolve(validators.rm_property_id()(param, fipsCode: '10003', apnUnformatted: '10001', apnSequence: '001')).then (value) ->
        value.should.equal('10003_10001_001')
    ]

  promiseIt 'should fail with invalid parcelId', () ->
    [
      expectReject(validators.rm_property_id()(param, stateCode: 'DE', county: 'New Castle', parcelId: ''), DataValidationError)
      expectReject(validators.rm_property_id()(param, stateCode: 'DE', county: 'New Castle', parcelId: null), DataValidationError)
      expectReject(validators.rm_property_id()(param, stateCode: 'DE', county: 'New Castle'), DataValidationError)
    ]

  promiseIt 'should fail with invalid fipsCode', () ->
    [
      expectReject(validators.rm_property_id()(param, stateCode: '', county: 'New Castle', parcelId: '10001'), DataValidationError)
      expectReject(validators.rm_property_id()(param, stateCode: 'DE', county: '', parcelId: '10001'), DataValidationError)
      expectReject(validators.rm_property_id()(param, fipsCode: '', parcelId: '10001'), DataValidationError)
    ]
