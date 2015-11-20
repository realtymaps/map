_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
doValidationSteps = require './util.impl.doValidationSteps'
logger = require '../../config/logger'

module.exports = (options = {}) ->
  (param, values) -> Promise.try () ->
    if !values
      return null
    if options.json
      values = JSON.parse values
    if options.pluck
      return values[options.pluck]
    if !_.isPlainObject values
      return Promise.reject new DataValidationError('plain object expected', param, values)
    if options.isEmpty && !_.isEmpty values
      return Promise.reject new DataValidationError('plain empty object expected', param, values)
    if options.isEmptyProtect && !_.isEmpty values
      return {}
    if options.subValidateSeparate
      # subValidateSeparate can be an object of validations/transformations suitable for use in validateAndTransform()
      # (including arrays of iteratively applied functions).  Each validation/transformation in the object is applied to
      # the corresponding element of the object, and remaining elements are passed unchanged
      separatePromises = _.clone(values)
      for key, subValidation of options.subValidateSeparate
        separatePromises[key] = doValidationSteps(subValidation, param, values[key])
      return Promise.props separatePromises
    else if options.subValidateEach
      # subValidateEach can be any validation/transformation suitable for use in validateAndTransform() (including
      # an array of iteratively applied functions), except these validators are also passed the key as an additional
      # parameter.  The validation/transformation is applied to each element of the object
      allPromises = {}
      for key, value of values
        allPromises[key] = doValidationSteps(options.subValidateEach, param, value)
      return Promise.props allPromises
    else
      return values
