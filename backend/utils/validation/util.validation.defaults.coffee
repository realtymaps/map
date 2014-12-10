Promise = require "bluebird"
ParamValidationError = require './util.error.paramValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if _.isArray(options.test) and (value in options.test) ||
    _.isFunction(options.test) and options.test(value) ||
    !_.isArray(options.test) and !_.isFunction(options.test) and !value?
      return options.defaultValue
    else
      return value
 