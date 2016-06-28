Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
require '../../../common/extensions/strings'
stateCodeLookup = require '../util.stateCodeLookup'
logger = require('../../config/logger').spawn('validation:address')

module.exports = (options = {}) ->
  (param, value) ->
    Promise.try () ->
      if !value.state || value.state.length == 2
        return value.state
      else
        return stateCodeLookup(value.state)
    .then (stateCode) ->

      if !value
        return null

      result =
        strength: 0

      if value.careOf
        result.careOf = "c/o #{value.careOf.toInitCaps()}"
        result.strength += 3

      if !value.showStreetInfo? || value.showStreetInfo
        if value.streetNum && value.streetName && value.streetSuffix
          if value.streetNum
            result.strength += 10
            numParts = [value.streetNum]
            if value.streetNumPrefix
              result.strength += 1
              numParts.unshift(value.streetNumPrefix)
            if value.streetNumSuffix
              result.strength += 1
              numParts.push(value.streetNumSuffix)

          if value.streetName
            result.strength += 10
            nameParts = [value.streetName.toInitCaps()]
            if value.streetDirPrefix
              result.strength += 1
              nameParts.unshift(value.streetDirPrefix)
            if value.streetSuffix
              result.strength += 5
              nameParts.push(value.streetSuffix.toInitCaps())
            if value.streetDirSuffix
              result.strength += 1
              nameParts.push(value.streetDirSuffix)

          if numParts
            streetParts = numParts
          else
            streetParts = []
          if nameParts
            streetParts = streetParts.concat(nameParts)
            result.street = streetParts.join(' ').toInitCaps()
          else
            result.strength = 0

          if value.unit
            result.strength += 10
            result.unit = value.unit
          else if value.unitNum
            result.strength += 5
            result.unit = "Unit #{value.unitNum}"
        else if value.streetFull
          throw new DataValidationError("Need street num, name, & suffix. It may be necessary to parse these from streetFull.", param, value)

      cityParts = []

      if value.city
        result.strength += 10
        cityParts.push(value.city.toInitCaps())

      if stateCode
        result.strength += 5
        if cityParts.length > 0
          cityParts[0] += ','
        cityParts.push(stateCode.toUpperCase())

      result.citystate = cityParts.join(' ')

      if value.zip9
        result.strength += 7
        result.zip = value.zip9
      else if value.zip
        result.strength += 5
        result.zip = value.zip
        if value.zip4
          result.strength += 2
          result.zip = "#{result.zip}-#{value.zip4}"
      else
        throw new DataValidationError("Need zip!", param, value)

      minStrength = options.minStrength ? 20
      if result.strength < minStrength
        #throw new DataValidationError("not enough address info provided; minStrength: #{minStrength} vs strength: #{result.strength}", param, value)
        return null

      logger.debug result
      return result
