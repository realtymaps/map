Promise = require 'bluebird'
stringValidation = require './util.validation.string'
objectValidation = require './util.validation.object'
logger = require '../../config/logger'

module.exports = (options = {}) ->
  composite = objectValidation(subValidateEach: stringValidation(options))
  (param, value) -> Promise.try () ->
    if !value
      return null

    composite(param, value).then (strings) ->

      if strings.full
        return strings.full

      parts = []
      if strings.first
        parts.push(strings.first)
      if strings.middle
        parts.push(strings.middle)
      if strings.last
        parts.push(strings.last)

      return parts.join(' ')
