Promise = require 'bluebird'
DataValidationError = require './util.error.dataValidation'
arrayValidation = require './util.validation.array'
fipsValidation = require './util.validation.fips'
stringValidation = require './util.validation.string'
defaultsValidation = require './util.validation.defaults'
objectValidation = require './util.validation.object'


# TODO: this will need to do sophisticated address-based lookups as well

module.exports = (options = {}) ->
  dataSource = options.dataSource ? 'mls'
  composite =  arrayValidation
    subValidateSeparate: [
      fipsValidation({dataSource: dataSource})
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

    if dataSource == 'mls' && ( !value.stateCode || !value.county || !value.parcelId )
      throw new DataValidationError('state, county, and parcelId are all required', param, value)

    com = composite(param, [value, value])
    console.log "#### rm_prop_id validator"
    console.log "#### options:"
    console.log JSON.stringify(options)
    console.log "#### param:"
    console.log JSON.stringify(param)
    console.log "#### value:"
    console.log JSON.stringify(value)
    console.log "#### composite:"
    console.log JSON.stringify(com)    

    return com
