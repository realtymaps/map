Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    type = typeof(value)
    if value == '' || (type != 'string' and type != 'number')
      return Promise.reject new DataValidationError("integer value required", param, value)
    numvalue = +value
    if isNaN(numvalue) || numvalue != Math.floor(numvalue)
      return Promise.reject new DataValidationError("integer value required", param, value)
    if options.min? and numvalue < options.min
      return Promise.reject new DataValidationError("value less than minimum: #{options.min}", param, value)
    if options.max? and numvalue > options.max
      return Promise.reject new DataValidationError("value larger than maximum: #{options.max}", param, value)
    return numvalue
