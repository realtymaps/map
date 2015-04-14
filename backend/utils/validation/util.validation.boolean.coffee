Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if typeof(value) == 'boolean'
      return value
    if value == 'true' || value == 'false'
      return value == 'true'

    return Promise.reject new DataValidationError("boolean value required", param, value)
