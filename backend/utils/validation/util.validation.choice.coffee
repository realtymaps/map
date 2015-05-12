_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if options.equalsTester?
      choice = _.find(options.choices, options.equalsTester.bind(null, value))
      if choice?
        return choice
    else if value in options.choices
      return value
    if !value? or value == ''
      return null
    return Promise.reject new DataValidationError("unrecognized value, options are: #{JSON.stringify(options.choices)}", param, value)
