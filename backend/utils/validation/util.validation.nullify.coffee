_ = require 'lodash'
validators = require '../util.validation'


module.exports = (options = {}) ->
  if options.value?
    values = [options.value]
  else
    values = options.values
  return validators.defaults(test: values, defaultValue: null)
