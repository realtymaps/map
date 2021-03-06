_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
doValidationSteps = require './util.impl.doValidationSteps'

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
        return Promise.reject new DataValidationError('array of values expected', param, values)
      if options.minLength? and arrayValues.length < options.minLength
        return Promise.reject new DataValidationError("array smaller than minimum: #{options.minLength}", param, values)
      if options.maxLength? and arrayValues.length > options.maxLength
        return Promise.reject new DataValidationError("array larger than maximum: #{options.maxLength}", param, values)
      if options.subValidateSeparate
        # subValidateSeparate can be an array of validations/transformations suitable for use in validateAndTransform()
        # (including arrays of iteratively applied functions).  Each validation/transformation in the array is applied to
        # the corresponding element of the array, and remaining elements are passed unchanged
        separatePromises = for subValidation, index in options.subValidateSeparate
          doValidationSteps(subValidation, param, arrayValues[index])
        return Promise.all separatePromises.concat(arrayValues.slice(options.subValidateSeparate.length))
      else if options.subValidateEach
        # subValidateEach can be any validation/transformation suitable for use in validateAndTransform() (including
        # an array of iteratively applied functions), except these validators are also passed the index and length
        # of the array as additional parameters.  The validation/transformation is applied to each element of the array
        return Promise.map arrayValues, doValidationSteps.bind(null, options.subValidateEach, param)
      else
        return arrayValues
    .then (arrayValues) ->
      if !arrayValues
        return null
      if options.join?
        return arrayValues.join(options.join)
      else
        return arrayValues
