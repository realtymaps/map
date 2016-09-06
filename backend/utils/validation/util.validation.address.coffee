Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
require '../../../common/extensions/strings'
logger = require('../../config/logger').spawn('validation:address')
usStates = require '../../../common/utils/util.usStates'
_ = require 'lodash'
regexEscape = require 'escape-string-regexp'


module.exports = (options = {}) ->
  (param, value) ->
    Promise.try () ->
      if !value.state || value.state.length == 2
        return value.state
      else
        return usStates.getByName(value.state)?.code
    .then (stateCode) ->

      if !value
        return null

      result = {}

      if value.careOf
        result.co = "c/o #{value.careOf.toInitCaps()}"

      if value.unitNum
        result.unit = "#{value.unitNum}".trim()
        if value.unitType
          result.unit = "#{value.unitType} #{result.unit}"
      else if value.unitType
        result.unit = value.unitType

      if value.streetNum && value.streetName && value.streetSuffix
        if value.streetNum
          numParts = [value.streetNum]
          if value.streetNumPrefix
            numParts.unshift(value.streetNumPrefix)
          if value.streetNumSuffix
            numParts.push(value.streetNumSuffix)

        if value.streetName
          nameParts = [value.streetName.toInitCaps()]
          if value.streetDirPrefix
            nameParts.unshift(value.streetDirPrefix)
          if value.streetSuffix
            nameParts.push(value.streetSuffix.toInitCaps())
          if value.streetDirSuffix
            nameParts.push(value.streetDirSuffix)

        if numParts
          streetParts = numParts
        else
          streetParts = []
        if nameParts
          streetParts = streetParts.concat(nameParts)
          result.street = streetParts.join(' ').toInitCaps()

      else if value.streetFull
        result.street = value.streetFull
        if result.unit
          # Scrub the unit part of the street address
          unitRe = new RegExp("\\W+#{regexEscape(result.unit)}\\W+", 'i')
          result.street = result.street.replace(result.street.match(unitRe)?[0], '')

      cityParts = []

      if value.city
        cityParts.push(value.city.toInitCaps())

      if stateCode
        if cityParts.length > 0
          cityParts[0] += ','
        cityParts.push(stateCode.toUpperCase())

      result.citystate = cityParts.join(' ')

      if value.zip9
        result.zip = value.zip9
      else if value.zip
        result.zip = value.zip
        if value.zip4
          result.zip = "#{result.zip}-#{value.zip4}"

      # Clean up whitespace in all fields. This is the last step so earlier regexes can use the original values.
      result = _.mapValues result, (v) ->
        v.replace(/\s{2,}/g, ' ').trim()

      logger.debug result
      return result
