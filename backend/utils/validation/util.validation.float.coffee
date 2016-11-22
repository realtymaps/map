Promise = require 'bluebird'
_ = require 'lodash'
DataValidationError = require '../errors/util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return null
    numvalue = +value
    if isNaN(numvalue)
      return Promise.reject new DataValidationError('invalid data type given for numeric value', param, value)

    if options.implicitDecimals?
      numvalue /= Math.pow(10, options.implicitDecimals)
    if options.min? and numvalue < options.min
      return Promise.reject new DataValidationError("value less than minimum: #{options.min}", param, value)
    if options.max? and numvalue > options.max
      return Promise.reject new DataValidationError("value larger than maximum: #{options.max}", param, value)

    return numvalue
