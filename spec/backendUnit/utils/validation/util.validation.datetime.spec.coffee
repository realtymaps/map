{basePath} = require '../../globalSetup'
{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject} = require('../../../specUtils/promiseUtils')

console.log "datetime spec"

describe 'datetime validator', ->
  param = 'fake'

  it "should output with correct outputFormat", () ->
    expectedOutput = 'January 1st, 2016'
    options =
      outputFormat: "MMMM Do, YYYY"
    value = "2016-01-01T00:00:00.000"

    expectResolve(validators.datetime(options)(param, value))
    .then (dtString) ->
      dtString.should.be.equal expectedOutput
