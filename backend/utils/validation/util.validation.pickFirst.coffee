_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
arrayValidation = require './util.validation.array'
doValidation = require './util.impl.doValidation'
logger = require '../../config/logger'

module.exports = (options = {}) ->
  (param, values) ->
    if !values?
      return null
    Promise.try () ->
      arrayValidation()(param,values)
    .then (arrayValues) ->
      if !options.criteria
        return arrayValues
      Promise.settle(_.map(arrayValues, doValidation.bind(null, options.criteria, param)))
    .then (validatedValues) ->
      for inspection in validatedValues
        if inspection.isFulfilled()
          return inspection.value()
      throw new DataValidationError("no array elements fulfilled validation criteria", param, values)
