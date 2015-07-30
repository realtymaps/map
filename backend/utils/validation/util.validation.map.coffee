_ = require 'lodash'
Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if value in options.map
      return options.map(value)
    if !value? || value == ''
      return null
    if options.passUmapped
      return value
    return Promise.reject new DataValidationError("unmappable value, options are: #{JSON.stringify(_.keys(options.map))}", param, value)
