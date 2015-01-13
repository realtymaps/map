Promise = require "bluebird"
ParamValidationError = require './util.error.paramValidation'
StingToBoolean = require '../util.stringToBoolean.coffee'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if value == '' || not StingToBoolean.isBoolean value
      return Promise.reject new ParamValidationError("boolean value required", param, value)
    return StingToBoolean.isTrue(value)
