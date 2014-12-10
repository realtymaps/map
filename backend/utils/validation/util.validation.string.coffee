Promise = require "bluebird"
ParamValidationError = require './util.error.paramValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !_.isString(value)
      return Promise.reject new ParamValidationError("string value required", param, value)
    if options.minLength? and value.length < options.minLength
      return Promise.reject new ParamValidationError("string shorter than minimum length: #{options.minLength}", param, value)
    if options.maxLength? and value.length > options.maxLength
      return Promise.reject new ParamValidationError("string longer than maximum length: #{options.maxLength}", param, value)
    if options.regex?
      regex = new RegExp(options.regex)
      if not regex.test(value)
        return Promise.reject new ParamValidationError("string does not match regex: #{regex}", param, value)
    
    transformedValue = value
    
    if options.replace?
      transformedValue = transformedValue.replace(options.replace[0], options.replace[1])
    if (options.forceLowerCase)
      transformedValue = transformedValue.toLowerCase()
    else if (options.forceUpperCase)
      transformedValue = transformedValue.toUpperCase()
    return transformedValue
