config = require '../config/config.coffee'
Promise = require 'bluebird'
memoize = require 'memoizee'
_ = require 'lodash'
{hiddenRequire} = require '../../common/utils/webpackHack.coffee'
memoize.promise ?= () ->


protectedConfigPromise = () ->
  # dependencies are here to keep karma happy
  # this prevents having to have a requires of *.coffee down through
  externalAccounts = hiddenRequire '../../backend/services/service.externalAccounts'
  cartodbConfig = hiddenRequire '../../backend/config/cartodb/cartodb'

  ret = {}

  mapBoxPromise = externalAccounts.getAccountInfo('mapbox')
  .then (accountInfo) ->
    ret.mapbox = accountInfo.api_key

  cartoDbPromise = cartodbConfig()
  .then (config) ->
    ret.cartodb = config

  googlePromise = externalAccounts.getAccountInfo('googlemaps')
  .catch (err) ->
    null
  .then (accountInfo) ->
    ret.google = accountInfo?.api_key ? null

  stripePromise = externalAccounts.getAccountInfo 'stripe'
  .then ({other}) ->
    ret.stripe = _.pick other, ['public_live_api_key', 'public_test_api_key']

  Promise.all [
    mapBoxPromise
    cartoDbPromise
    googlePromise
    stripePromise
  ]
  .then () ->
    ret


# if safe config becomes more complicated we may want to make this memoizee function
# NOTE: NEVER send over the whole config object as many field values should not be exposed
safeConfig =
  ANGULAR: config.ANGULAR
  debugLevels: config.LOGGING.ENABLE

module.exports = {
  safeConfig
  protectedConfigPromise: memoize.promise(protectedConfigPromise, maxAge: 10*60*1000)
}
