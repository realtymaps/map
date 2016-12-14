_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
arrayValidation = require './util.validation.array'
doValidationSteps = require './util.impl.doValidationSteps'
# coffeelint: disable=check_scope
logger = require('../../config/logger').spawn("util:validation:pickFirst")
# coffeelint: enable=check_scope

module.exports = (options = {}) ->
  (param, values) ->
    if !values?
      return null
    Promise.try () ->
      arrayValidation()(param,values)
    .then (arrayValues) ->
      if arrayValues == null
        return null
      if !options.criteria
        if arrayValues.length == 0
          throw new DataValidationError('no array elements given', param, values)
        else
          for value in arrayValues
            if value?
              return value
          return null
      Promise.settle(_.map(arrayValues, doValidationSteps.bind(null, options.criteria, param)))
      .then (validatedValues) ->
        fulfilledNull = false
        for inspection in validatedValues
          if inspection.isFulfilled()
            if inspection.value()?
              return inspection.value()
            fulfilledNull = true
        if !fulfilledNull
          throw new DataValidationError('no array elements fulfilled validation criteria', param, values)
        return null
