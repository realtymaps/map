Promise = require 'bluebird'
currencyValidation = require './util.validation.currency'
objectValidation = require './util.validation.object'


# convenience validator

module.exports = (options = {}) ->
  composite = objectValidation
    subValidateSeparate:
      amount: currencyValidation(options)

  (param, value) -> Promise.try () ->
    if !value
      return null

    composite(param, value)
    .then (obj) ->
      if value.scale == 'K'
        obj.amount *= 10
      else if value.scale == 'T'
        obj.amount *= 100
      obj.amount
