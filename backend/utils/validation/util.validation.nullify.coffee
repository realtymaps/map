_ = require 'lodash'
defaultsValidation = require './util.validation.defaults'


module.exports = (options = {}) ->
  if options.value?
    values = [options.value]
  else
    values = options.values || options.matcher
  return defaultsValidation(test: values, defaultValue: null)
