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
        return strings.full.split(/[ ]+/g).join(' ').trim()

      parts = []
      if strings.first
        parts.push(strings.first.split(/[ ]+/g).join(' ').trim())
      if strings.middle
        parts.push(strings.middle.split(/[ ]+/g).join(' ').trim())
      if strings.last
        parts.push(strings.last.split(/[ ]+/g).join(' ').trim())
      if strings.suffix
        parts.push(strings.suffix.split(/[ ]+/g).join(' ').trim())

      return parts.join(' ')
