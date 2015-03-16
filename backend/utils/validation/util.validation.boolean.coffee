Promise = require "bluebird"
ParamValidationError = require './util.error.paramValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if typeof(value) == 'boolean'
      return value
    if value == 'true' || value == 'false'
      return if value != 'true'

    return Promise.reject new ParamValidationError("boolean value required", param, value)
