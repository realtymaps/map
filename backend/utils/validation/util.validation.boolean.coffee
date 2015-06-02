Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
_ = require 'lodash'

module.exports = (options = {}) ->
  if !_.isArray(options.truthy) && options.truthy != undefined
    truthy = [options.truthy]
  if !_.isArray(options.falsy) && options.falsy != undefined
    falsy = [options.falsy]
  truthyReturnValue = if options.invert? then !options.invert else !!options.invert
    
  (param, value) -> Promise.try () ->
    if !value?
      return null

    if options.forceLowerCase && typeof(value) == 'string'
      value = value.toLowerCase()

    if truthy == undefined
      if value
        return truthyReturnValue
    else if value in truthy
      return truthyReturnValue
    if falsy == undefined
      if value
        return !truthyReturnValue
    else if value in falsy
      return !truthyReturnValue
      
    return Promise.reject new DataValidationError("invalid data type given for boolean field", param, value)
