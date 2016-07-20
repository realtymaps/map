Promise = require 'bluebird'
stringValidation = require './util.validation.string'
floatValidation = require './util.validation.float'


# convenience validator

module.exports = (options = {}) ->
  [stringValidation(replace: [/[$,]/g, '']), floatValidation(options)]
