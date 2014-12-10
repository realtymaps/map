Promise = require "bluebird"
ParamValidationError = require './util.error.paramValidation'
doValidation = require './util.impl.doValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    doValidation(options.subValidation, param, value)
    .catch ParamValidationError, () ->
      Promise.resolve(options.defaultValue)
