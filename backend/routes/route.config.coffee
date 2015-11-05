logger = require '../config/logger'
auth = require '../utils/util.auth'
externalAccounts = require '../services/service.externalAccounts'
cartodbConfig = require '../config/cartodb/cartodb'


module.exports =
  mapboxKey:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      externalAccounts.getAccountInfo('mapbox')
      .then (accountInfo) ->
        res.send accountInfo.api_key

  cartodb:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      cartodbConfig().then (config) ->
        res.send(config)

  google:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      externalAccounts.getAccountInfo('googlemaps')
      .catch (err) ->
        null
      .then (accountInfo) ->
        if accountInfo?.api_key?
          res.send MAPS: API_KEY: accountInfo.api_key
        else
          res.send null
