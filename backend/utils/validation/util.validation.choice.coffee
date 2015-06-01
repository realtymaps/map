_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  if _.isArray(options.choices)
    choices = options.choices
    translations = null
  else
    translations = options.choices
    choices = Object.keys(translations)
  (param, value) -> Promise.try () ->
    if options.equalsTester?
      foundChoice = _.find(choices, options.equalsTester.bind(null, value))
      if foundChoice?
        return if translations then translations[foundChoice] else foundChoice
    else if value in choices
      return if translations then translations[value] else value
    if !value? or value == ''
      return null
    return Promise.reject new DataValidationError("unrecognized value, options are: #{JSON.stringify(choices)}", param, value)
