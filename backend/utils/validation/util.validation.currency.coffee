Promise = require "bluebird"
moment = require 'moment'
stringValidation = require './util.validation.string'
floatValidation = require './util.validation.float'


# convenience validator

module.exports = (options = {}) ->
  [stringValidation(replace: [/[$,]/g, '']), floatValidation()]
