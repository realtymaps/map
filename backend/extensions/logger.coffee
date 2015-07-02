{Logger} = require 'winston'
_ = require 'lodash'

Logger::functions = (thing) ->
  @debug _.functions thing
