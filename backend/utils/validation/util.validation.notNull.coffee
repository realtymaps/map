Promise = require 'bluebird'
DataValidationError = require './util.error.dataValidation'
gjv = require 'geojson-validation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return Promise.reject new DataValidationError('invalid data notNull field', param, value)
    return value
