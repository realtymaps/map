_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
require '../../../common/extensions/strings'
logger = require('../../config/logger').spawn 'util::validation::string'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value?
      return null
    if _.isNumber value and options.allowNumber
      value = value.toString()
    if !_.isString(value)
      return Promise.reject new DataValidationError('invalid data type given for string field', param, value)
    if options.minLength? and value.length < options.minLength
      return Promise.reject new DataValidationError("string shorter than minimum length: #{options.minLength}", param, value)
    if options.maxLength? and value.length > options.maxLength
      return Promise.reject new DataValidationError("string longer than maximum length: #{options.maxLength}", param, value)
    if options.regex?
      regex = new RegExp(options.regex)
      if not regex.test(value)
        return Promise.reject new DataValidationError("string does not match regex: #{regex}", param, value)

    transformedValue = value

    if options.null
      transformedValue = null
    if options.trim
      transformedValue = transformedValue.trim()
    if options.replace?
      logger.debug options.replace
      transformedValue = transformedValue.replace(options.replace[0], options.replace[1])
    if options.stripFormatting
      transformedValue = transformedValue.replace(/[^a-zA-Z0-9]/g, '')
    if (options.forceInitCaps)
      transformedValue = transformedValue.toInitCaps()
    if (options.toObject || options.parse)
      transformedValue = JSON.parse transformedValue
    else if (options.forceLowerCase)
      transformedValue = transformedValue.toLowerCase()
    else if (options.forceUpperCase)
      transformedValue = transformedValue.toUpperCase()
    return transformedValue
