_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !options.map
      return Promise.reject new DataValidationError("no map provided, options are: #{JSON.stringify(options)}", param, value)
    mapped = options.map[value]
    if mapped?
      return mapped
    if !value? || value == ''
      return null
    if options.passUnmapped
      return value
    return Promise.reject new DataValidationError("unmappable value, options are: #{JSON.stringify(_.keys(options.map))}", param, value)
