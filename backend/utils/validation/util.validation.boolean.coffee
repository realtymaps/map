Promise = require "bluebird"
ParamValidationError = require './util.error.paramValidation'
StringToBoolean = require '../../../common/utils/util.stringToBoolean'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if value == '' || not StringToBoolean.isBoolean value
      return Promise.reject new ParamValidationError("boolean value required", param, value)
    return StringToBoolean.isTrue(value)
