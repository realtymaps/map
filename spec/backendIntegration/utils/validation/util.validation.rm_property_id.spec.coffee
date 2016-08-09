Promise = require 'bluebird'
{basePath} = require '../../globalSetup'

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.rm_property_id()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve given a stateCode & county for fips lookup, a APN, and default 001', () ->
    [
      expectResolve(validators.rm_property_id()(param, stateCode: 'DE', county: 'New Castle', apn: '10001')).then (value) ->
        value.should.equal('10003_00000010001_001')
    ]

  promiseIt 'should resolve given a fipsCode, an APN, and sequenceNumber', () ->
    [
      expectResolve(validators.rm_property_id()(param, fipsCode: '10003', apn: '10001', sequenceNumber: '222')).then (value) ->
        value.should.equal('10003_00000010001_222')
    ]

  promiseIt 'should fail with invalid APN', () ->
    [
      expectReject(validators.rm_property_id()(param, stateCode: 'DE', county: 'New Castle', apn: ''), DataValidationError)
      expectReject(validators.rm_property_id()(param, stateCode: 'DE', county: 'New Castle', apn: null), DataValidationError)
      expectReject(validators.rm_property_id()(param, stateCode: 'DE', county: 'New Castle'), DataValidationError)
    ]

  promiseIt 'should fail with invalid fipsCode', () ->
    [
      expectReject(validators.rm_property_id()(param, stateCode: '', county: 'New Castle', apn: '10001'), DataValidationError)
      expectReject(validators.rm_property_id()(param, stateCode: 'DE', county: '', apn: '10001'), DataValidationError)
      expectReject(validators.rm_property_id()(param, fipsCode: '', apn: '10001'), DataValidationError)
    ]
