Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
arrayValidation = require './util.validation.array'
fipsValidation = require './util.validation.fips'
stringValidation = require './util.validation.string'
defaultsValidation = require './util.validation.defaults'
objectValidation = require './util.validation.object'


# TODO: this will need to do sophisticated address-based lookups as well

module.exports = (options = {}) ->
  composite =  arrayValidation
    subValidateSeparate: [
      fipsValidation()
      [
        objectValidation(pluck: 'parcelId')
        stringValidation(stripFormatting: true, regex: options.parcelRegex)
      ]
      defaultsValidation(defaultValue: '001')
    ]
    join: '_'

  (param, value) -> Promise.try () ->
    if !value
      return null
      
    if !value.stateCode || !value.county || !value.parcelId
      throw new DataValidationError("state, county, and parcelId are all required", param, value)
    
    return composite(param, value)
