_ = require 'lodash'
Promise = require 'bluebird'


module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !options.test? and (!value? or value == '') ||
    _.isArray(options.test) and (value in options.test) ||
    _.isFunction(options.test) and options.test(value)
      return options.defaultValue
    else
      return value
