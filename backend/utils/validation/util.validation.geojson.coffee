Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
gjv = require 'geojson-validation'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return null
    if !gjv.valid(value)
      return Promise.reject new DataValidationError('invalid data for geojson field', param, value)
    return value
