Promise = require 'bluebird'
logger = require '../../config/logger'
DataValidationError = require './util.error.dataValidation'
arrayValidation = require './util.validation.array'
fipsValidation = require './util.validation.fips'
stringValidation = require './util.validation.string'
defaultsValidation = require './util.validation.defaults'
objectValidation = require './util.validation.object'


# TODO: this will need to do sophisticated address-based lookups as well

module.exports = (options = {}) ->
  # value.stateCode && value.county && value.parcelId
  compositeVersion1 = arrayValidation
    subValidateSeparate: [
      fipsValidation()
      [
        objectValidation(pluck: 'parcelId')
        stringValidation(stripFormatting: true, regex: options.parcelRegex)
      ]
      defaultsValidation(defaultValue: '001')
    ]
    join: '_'

  # value.fipsCode && value.apnUnformatted && value.apnSequence
  compositeVersion2 = arrayValidation
    subValidateSeparate: [
      fipsValidation()
      stringValidation(stripFormatting: true)
      stringValidation()
    ]
    join: '_'

  (param, value) -> Promise.try () ->
    if !value
      return null

    if !(value.stateCode && value.county && value.parcelId) && (value.fipsCode && value.apnUnformatted && value.apnSequence)
      composite = compositeVersion2(param, [value.fipsCode, value.apnUnformatted, value.apnSequence])
    else if (value.stateCode && value.county && value.parcelId) && !(value.fipsCode && value.apnUnformatted && value.apnSequence)
      composite = compositeVersion1(param, [value, value])
    else
      throw new DataValidationError('either the fields state, county, and parcelId, OR fipsCode, apnUnformatted, and apnSequence are required', param, value)

    return composite
