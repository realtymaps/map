Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return null
    if typeof(value) == 'boolean'
      return value
    if value == 'true' || value == 'false'
      return value == 'true'

    return Promise.reject new DataValidationError("invalid data type given for boolean field", param, value)
