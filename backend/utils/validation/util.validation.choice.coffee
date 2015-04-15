Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if value == undefined
      return undefined
    if options.equalsTester?
      choice = _.find(options.choices, options.equalsTester.bind(null, value))
      if choice?
        return choice
    else if value in options.choices
      return value
    return Promise.reject new DataValidationError("unrecognized value, options are: #{JSON.stringify(options.choices)}", param, value)
