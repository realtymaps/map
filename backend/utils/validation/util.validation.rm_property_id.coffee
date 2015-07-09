Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
arrayValidation = require './util.validation.array'
fipsValidation = require './util.validation.fips'
stringValidation = require './util.validation.string'
defaultsValidation = require './util.validation.defaults'


# TODO: this will need to do sophisticated address-based lookups as well

module.exports = (options = {}) ->
  composite =  arrayValidation
    subValidateSeparate: [
      fipsValidation(states: options.states)
      stringValidation(stripFormatting: true, regex: options.parcelRegex)
      defaultsValidation(defaultValue: '001')
    ]
    join: '_'

  (param, value) -> Promise.try () ->
    if !value
      return null
    
    if !value[0] || !value[1]
      throw new DataValidationError("county and parcelId are both required", param, value)
    
    return composite(param, value)
