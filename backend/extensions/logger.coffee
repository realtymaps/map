{Logger} = require 'winston'
_ = require 'lodash'

Logger::functions = (thing) ->
  @debug _.functions thing

Logger::keys = (thing) ->
  @debug _.keys thing
