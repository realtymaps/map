Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if value == undefined
      return undefined
    if value == ''
      return Promise.reject new DataValidationError("numeric value required", param, value)
    numvalue = +value
    if isNaN(numvalue)
      return Promise.reject new DataValidationError("numeric value required", param, value)
    if options.min? and numvalue < options.min
      return Promise.reject new DataValidationError("value less than minimum: #{options.min}", param, value)
    if options.max? and numvalue > options.max
      return Promise.reject new DataValidationError("value larger than maximum: #{options.max}", param, value)
    return numvalue
