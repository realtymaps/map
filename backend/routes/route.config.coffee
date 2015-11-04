logger = require '../config/logger'
config = require '../config/config'
auth = require '../utils/util.auth'

module.exports =
  mapboxKey:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      key = config.MAPBOX.API_KEY
      res.send key

  cartodb:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      res.send config.CARTODB


  google:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      res.send config.GOOGLE
