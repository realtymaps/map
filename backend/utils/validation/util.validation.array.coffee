_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
doValidation = require './util.impl.doValidation'
logger = require '../../config/logger'

module.exports = (options = {}) ->
  (param, values) ->
    Promise.try () ->
      if !values
        return null
      if options.split? and _.isString(values)
        arrayValues = values.split(options.split)
      else
        arrayValues = values
    
      if !_.isArray arrayValues
        return Promise.reject new DataValidationError("array of values expected", param, values)
      if options.minLength? and arrayValues.length < options.minLength
        return Promise.reject new DataValidationError("array smaller than minimum: #{options.minLength}", param, values)
      if options.maxLength? and arrayValues.length > options.maxLength
        return Promise.reject new DataValidationError("array larger than maximum: #{options.maxLength}", param, values)
      if options.subValidateSeparate
        # subValidateSeparate can be an array of validations/transformations suitable for use in validateAndTransform()
        # (including arrays of iteratively applied functions).  Each validation/transformation in the array is applied to
        # the corresponding element of the array, and remaining elements are passed unchanged
        separatePromises = [ doValidation(subValidation, param, arrayValues[index]) for subValidation, index in options.subValidateSeparate ]
        return Promise.all separatePromises.concat(arrayValues.slice(options.subValidateSeparate.length))
      else if options.subValidateEach
        # subValidateEach can be any validation/transformation suitable for use in validateAndTransform() (including
        # an array of iteratively applied functions), except these validators are also passed the index and length
        # of the array as additional parameters.  The validation/transformation is applied to each element of the array
        return Promise.map arrayValues, doValidation.bind(null, options.subValidateEach, param)
      else
        return arrayValues
    .then (arrayValues) ->
      if options.join?
        return arrayValues.join(options.join)
      else
        return arrayValues
