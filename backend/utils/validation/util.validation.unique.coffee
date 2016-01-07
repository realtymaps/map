_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
{isUnique} = require '../../utils/util.sql.helpers'
logger = require '../../config/logger'
logName = "backend:validation.isUnique"

module.exports = (options = {}) ->
  # logger.debug logName + " created"
  # logger.debug.cyan options, true
  _.required options, ['tableFn', 'clauseGenFn', 'id'], true
  (param, value) -> Promise.try () ->
    logger.debug logName + " Called"
    logger.debug param, true
    logger.debug "value: #{value}"
    if !value?
      return null
    if !_.isString(value)
      return Promise.reject new DataValidationError('invalid data type given for unique field', param, value)

    transformedValue = value

    isUnique(options.tableFn, options.clauseGenFn(transformedValue), options.id, options.name)
    .then () ->
      logger.debug "transformed value: #{transformedValue}"
      transformedValue
    .catch () ->
      logger.error logName
      return Promise.reject new DataValidationError("value is not unique in the #{options.tableFn.name} table.", param, value)
