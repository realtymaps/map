Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
validators = require '../util.validation'


# TODO: this will need to do sophisticated address-based lookups as well

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value
      return null
    
    if !value[0] || !value[1]
      throw new DataValidationError("county and parcelId are both required", param, value)
    
    return validators.array
      subValidateSeparate: [
        validators.fips(states: options.states)
        validators.string(stripFormatting: true, regex: options.parcelRegex)
        validators.defaults(defaultValue: '001')
      ]
      join: '_'
