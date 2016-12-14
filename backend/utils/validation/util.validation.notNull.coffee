Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'


module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value? or value == ''
      return Promise.reject new DataValidationError('invalid data notNull field', param, value)
    return value
