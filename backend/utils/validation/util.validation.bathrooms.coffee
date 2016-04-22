Promise = require 'bluebird'
integerValidation = require './util.validation.integer'
floatValidation = require './util.validation.float'
objectValidation = require './util.validation.object'


module.exports = (options = {}) ->
  composite = objectValidation
    subValidateSeparate:
      full: integerValidation()
      half: integerValidation()
      total: floatValidation()

  (param, value) -> Promise.try () ->
    if !value
      return null

    composite(param, value)
    .then (bareValues) ->
      if bareValues.full? && bareValues.half?
        result =
          label: 'Baths (Full / Half)'
          value: "#{bareValues.full} / #{bareValues.half}"
        result.filter = bareValues.full
        if bareValues.half > 0
          result.filter += 0.5
        return result
      else if bareValues.total?
        numStr = Math.floor(bareValues.total*10).toString()
        numStr = numStr[0...-1]+'.'+numStr[-1..]
        result =
          label: 'Baths'
          value: numStr
        result.filter = Math.floor(bareValues.total)
        if bareValues.total - result.filter > 0
          result.filter += 0.5
        return result
      else
        return null
