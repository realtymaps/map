_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
{isUnique} = require '../../utils/util.sql.helpers'

module.exports = (options = {}) ->
  _.required options, ['tableFn', 'clauseGenFn', 'id'], true
  (param, value) -> Promise.try () ->
    if !value?
      return null
    if !_.isString(value)
      return Promise.reject new DataValidationError("invalid data type given for unique field", param, value)

    transformedValue = value

    isUnique(options.tableFn, options.clauseGenFn(transformedValue), options.id, options.name)
    .then () ->
      transformedValue
    .catch () ->
      return Promise.reject new DataValidationError("value is not unique in the #{options.tableFn.name} table.", param, value)
