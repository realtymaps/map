Promise = require "bluebird"
DataValidationError = require './util.error.dataValidation'
require '../../../common/extensions/strings'


module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value
      return null

    if !value.city || !value.state || !(value.zip || value.zip9)
      throw new DataValidationError("required major address info not provided", param, value)

    if (!value.streetName || !value.streetNum) && !value.streetFull && value.showStreetInfo
      throw new DataValidationError("required street address info not provided", param, value)
    
    result = []

    if value.showStreetInfo
      if value.streetFull
        result.push value.streetFull.toInitCaps()
      else
        numParts = [value.streetNum]
        if value.streetNumPrefix
          numParts.unshift(value.streetNumPrefix)
        if value.streetNumSuffix
          numParts.push(value.streetNumSuffix)
    
        nameParts = [value.streetName.toInitCaps()]
        if value.streetDirPrefix
          numParts.unshift(value.streetDirPrefix)
        if value.streetSuffix
          numParts.push(value.streetSuffix.toInitCaps())
        if value.streetDirSuffix
          numParts.push(value.streetDirSuffix)
        
        result.push numParts.concat(nameParts).join(' ').toInitCaps()
          
        if value.unitNum
          result.push "Unit #{value.unitNum}"
        else if value.unit
          result.push value.unit

    if value.zip9
      zip = value.zip9
    else
      zip = value.zip
      if value.zip4
        zip = "#{zip}-#{value.zip4}"
    result.push "#{value.city.toInitCaps()}, #{value.state.toUpperCase()} #{zip}"
    
    return result
