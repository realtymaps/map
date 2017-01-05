_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
{isUnique} = require '../../utils/util.sql.helpers'
require '../../extensions/lodash'
# logger = require('../../config/logger').spawn("validation:isUnique")

module.exports = (options = {}) ->
  # logger.debug "created"
  # logger.debug.cyan options, true
  _.required options, ['tableFn', 'clauseGenFn', 'id'], true
  {tableFn, clauseGenFn, id, name} = options

  (param, value) -> Promise.try () ->
    # logger.debug "called"
    # logger.debug param, true
    # logger.debug "value: #{value}"
    if !value?
      return null
    if !_.isString(value)
      return Promise.reject new DataValidationError('invalid data type given for unique field', param, value)

    transformedValue = value

    isUnique({tableFn, whereClause: clauseGenFn(transformedValue), id, name})
    .then () ->
      # logger.debug "transformed value: #{transformedValue}"
      transformedValue
    .catch () ->
      # logger.error logName
      return Promise.reject new DataValidationError("value is not unique in the #{tableFn.name} table.", param, value)
