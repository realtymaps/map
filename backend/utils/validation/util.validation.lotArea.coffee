Promise = require 'bluebird'
floatValidation = require './util.validation.float'
objectValidation = require './util.validation.object'


module.exports = (options = {}) ->
  composite = objectValidation
    subValidateSeparate:
      acres: floatValidation(options)
      sqft: floatValidation(options)

  return (param, value) -> Promise.try () ->
    if !value
      return null
    composite(param, value)
    .then (intermediate) ->
      if intermediate.acres
        return intermediate.acres
      else if intermediate.sqft
        return intermediate.sqft/43560
      else
        return null
