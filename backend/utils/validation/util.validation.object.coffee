_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
logger = require '../../config/logger'
validateAndTransform = require './util.impl.validateAndTransform'

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
    if options.isNullProtect && !_.isEmpty values
      return null
    if options.subValidateSeparate or options.subValidateEach #(handle object or array)
      # subValidateSeparate can be an object of validations/transformations suitable for use in validateAndTransform()
      # (including arrays of iteratively applied functions).  Each validation/transformation in the object is applied to
      # the corresponding element of the object, and remaining elements are passed unchanged
      validateAndTransform values, options.subValidateSeparate or options.subValidateEach
    else
      return values
