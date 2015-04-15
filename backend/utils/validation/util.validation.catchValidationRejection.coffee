Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
doValidation = require './util.impl.doValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    doValidation(options.subValidation, param, value)
    .catch DataValidationError, () ->
      Promise.resolve(options.defaultValue)
