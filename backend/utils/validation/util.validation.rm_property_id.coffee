Promise = require 'bluebird'
# coffeelint: disable=check_scope
logger = require('../../config/logger').spawn("util:validation:rm_property_id")
# coffeelint: enable=check_scope
DataValidationError = require '../errors/util.error.dataValidation'
arrayValidation = require './util.validation.array'
fipsValidation = require './util.validation.fips'
stringValidation = require './util.validation.string'
defaultsValidation = require './util.validation.defaults'


# TODO: this will need to do sophisticated address-based lookups as well

module.exports = (options = {}) ->
  composite = arrayValidation
    subValidateSeparate: [
      fipsValidation()
      stringValidation(stripFormatting: true, regex: options.parcelRegex, leftPad: {target: 11, padding: '0'})
      defaultsValidation(defaultValue: '001')
    ]
    join: '_'

  (param, value) -> Promise.try () ->
    if !value
      return null

    if !value.fipsCode && (!value.stateCode || !value.county)
      throw new DataValidationError('either fipsCode, or state plus county is required', param, value)

    if !value.apn
      throw new DataValidationError('APN is required', param, value)

    return composite(param, [value, value.apn, value.sequenceNumber])
