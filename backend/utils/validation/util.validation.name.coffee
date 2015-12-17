Promise = require 'bluebird'
stringValidation = require './util.validation.string'
objectValidation = require './util.validation.object'


module.exports = (options = {}) ->
  composite = objectValidation(subValidateEach: stringValidation(options))
  (param, value) -> Promise.try () ->
    if !value
      return null

    strings = composite(param, value)

    parts = []
    if strings.first
      parts.push(strings.first)
    if strings.middle
      parts.push(strings.middle)
    if strings.last
      parts.push(strings.last)

    return parts.join(' ')
