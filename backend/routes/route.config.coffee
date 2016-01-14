logger = require '../config/logger'
auth = require '../utils/util.auth'
externalAccounts = require '../services/service.externalAccounts'
cartodbConfig = require '../config/cartodb/cartodb'
googleMapsConfig = require '../config/googleMaps'
_ = require 'lodash'

module.exports =
  mapboxKey:
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      externalAccounts.getAccountInfo('mapbox')
      .then (accountInfo) ->
        res.send accountInfo.api_key

  cartodb:
    middleware: auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      cartodbConfig().then (config) ->
        res.send(config)

  google:
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

  stripe:
    handle: (req, res, next) ->
      externalAccounts.getAccountInfo 'stripe'
      .then ({other}) ->
        res.send _.pick other, ['public_live_api_key', 'public_test_api_key']

  asyncAPIs:
    handle: (req, res, next) ->
      #any js apis that need to be loaded async go here
      res.send [
        # googleMapsConfig.locals.mapsSdkUrl
      ]
