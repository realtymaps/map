_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
require '../../../common/extensions/strings'
logger = require('../../config/logger').spawn 'util:validation:string'

module.exports = (options = {}) ->
  if options.in? && !Array.isArray(options.in)
    throw new Error("options.in must be of type Array.")
  (param, value) -> Promise.try () ->
    if !value?
      return null
    if _.isNumber(value) and options.allowNumber
      value = value.toString()
    if !_.isString(value)
      return Promise.reject new DataValidationError('invalid data type given for string field', param, value)
    if options.minLength? and value.length < options.minLength
      return Promise.reject new DataValidationError("string shorter than minimum length: #{options.minLength}", param, value)
    if options.maxLength? and value.length > options.maxLength
      return Promise.reject new DataValidationError("string longer than maximum length: #{options.maxLength}", param, value)
    if options.regex?

      testedRegex = null

      testRegex = (regex) ->
        regex = new RegExp(regex)
        if !regex.test(value)
          return Promise.reject new DataValidationError("string does not match regex: #{regex}", param, value)

      if Array.isArray(options.regex)
        for r in options.regex
          if (testedRegex = testRegex(r))?
            break
      else
        testedRegex = testRegex(options.regex)

      if testedRegex?
        return testedRegex

    if options.in?
      if !_.includes options.in, value
        return Promise.reject new DataValidationError("string is not in: [#{options.in.join(',')}]", param, value)

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
    if options.leftPad
      while transformedValue.length < options.leftPad.target
        transformedValue = options.leftPad.padding + transformedValue
    else if options.rightPad
      while transformedValue.length < options.rightPad.target
        transformedValue = transformedValue + options.rightPad.padding
    return transformedValue
