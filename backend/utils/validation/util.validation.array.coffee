Promise = require "bluebird"
ParamValidationError = require './util.error.paramValidation'
doValidation = require './util.impl.doValidation'
logger = require '../../config/logger'

module.exports = (options = {}) ->
  (param, values) -> Promise.try () ->
    if options.split? and _.isString(values)
      arrayValues = values.split(options.split)
    else
      arrayValues = values

#    logger.debug "param: #{param}"
#    logger.debug "values: #{values}"
    if !_.isArray arrayValues
      return Promise.reject new ParamValidationError("array of values expected", param, values)
    if options.minLength? and arrayValues.length < options.minLength
      return Promise.reject new ParamValidationError("array smaller than minimum: #{options.minLength}", param, values)
    if options.maxLength? and arrayValues.length > options.maxLength
      return Promise.reject new ParamValidationError("array larger than maximum: #{options.maxLength}", param, values)
    if options.subValidation
      # subValidation can be any validation/transformation suitable for use in validateAndTransform() (including
      # an array of iteratively applied functions), except these validators are also passed the index and length
      # of the array as additional paramters
      return Promise.map arrayValues, doValidation.bind(null, options.subValidation, param)
    else
      return arrayValues
