logger = require('../config/logger').spawn("route:config")
auth = require '../utils/util.auth'
externalAccounts = require '../services/service.externalAccounts'
cartodbConfig = require '../config/cartodb/cartodb'
googleMapsConfig = require '../config/googleMaps'
config = require '../config/config'
_ = require 'lodash'
internals = require './route.config.internals'

module.exports =
  safeConfig:
    handle: (req, res, next) ->
      logger.debug "sending safeConfig.: #{internals.safeConfig}"
      res.send internals.safeConfig

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
