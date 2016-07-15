Promise = require 'bluebird'
currencyValidation = require './util.validation.currency'
objectValidation = require './util.validation.object'


# convenience validator

module.exports = (options = {}) ->
  validator = currencyValidation(options)

  (param, value) -> Promise.try () ->
    if !value
      return null

    amount = validator(param, value.amount)
    if value.scale == 'K'
      amount *= 10
    else if value.scale == 'T'
      amount *= 100

    amount
