_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  if _.isArray(options.choices)
    choices = options.choices
    translations = {}
    for choice in choices
      translations[choice] = choice
  else
    translations = options.choices
    choices = Object.keys(translations)
  (param, value) -> Promise.try () ->
    if options.equalsTester?
      choice = _.find(choices, options.equalsTester.bind(null, value))
      if choice?
        return translations[choice]
    else if value in choices
      return translations[value]
    if !value? or value == ''
      return null
    return Promise.reject new DataValidationError("unrecognized value, options are: #{JSON.stringify(choices)}", param, value)
