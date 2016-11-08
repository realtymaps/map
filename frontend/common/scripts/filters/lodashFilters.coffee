_ = require 'lodash'
mod = require '../module.coffee'

_.each _.methods(_), (methodName) ->
  filter = _.bind(_[methodName], _)
  factory = -> filter
  mod.filter("_#{methodName}", factory)
