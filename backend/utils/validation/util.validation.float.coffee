Promise = require "bluebird"
ParamValidationError = require './util.error.paramValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if value == ''
      return Promise.reject new ParamValidationError("numeric value required", param, value)
    numvalue = +value
    if isNaN(numvalue)
      return Promise.reject new ParamValidationError("numeric value required", param, value)
    if options.min? and numvalue < options.min
      return Promise.reject new ParamValidationError("value less than minimum: #{options.min}", param, value)
    if options.max? and numvalue > options.max
      return Promise.reject new ParamValidationError("value larger than maximum: #{options.max}", param, value)
    return numvalue
