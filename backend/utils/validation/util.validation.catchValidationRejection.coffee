Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
doValidationSteps = require './util.impl.doValidationSteps'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    doValidationSteps(options.subValidation, param, value)
    .catch DataValidationError, () ->
      Promise.resolve(options.defaultValue)
