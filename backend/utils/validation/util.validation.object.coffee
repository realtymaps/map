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
    if options.subValidateSeparate #against INDIVIDUAL (Separate) validation function
      # applies transformations for a sub object or array
      validateAndTransform values, options.subValidateSeparate

    else if options.subValidateEach #against SAME validaion function
      # applies validate and transform against the same validation options for all values
      allOptions = _.mapValues values, () ->
        options.subValidateEach
      validateAndTransform values, allOptions

    else
      return values
