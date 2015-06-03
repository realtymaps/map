Promise = require "bluebird"
validators = require '../util.validation'
moment = require 'moment'


# convenience validator

module.exports = (options = {}) ->
  [validators.string(replace: [/[$,]/g, ""]), validators.float()]
