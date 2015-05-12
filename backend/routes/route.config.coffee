logger = require '../config/logger'
config = require '../config/config'
memoize = require 'memoizee'

module.exports =
  mapboxKey: memoize (req, res, next) ->
    key = config.MAPBOX.API_KEY
    res.send key

  cartodb: memoize (req, res, next) ->
    res.send config.CARTODB
