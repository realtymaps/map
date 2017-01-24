config = require '../config/config.coffee'
Promise = require 'bluebird'
memoize = require 'memoizee'
{hiddenRequire} = require '../../common/utils/webpackHack.coffee'
# karma hack workaround
memoize.promise ?= () ->

safeConfigPromise = () ->
  safeConfig =
    debugLevels: config.LOGGING.ENABLE
    EMAIL_VERIFY: config.EMAIL_VERIFY
    SIGNUP_ENABLED: config.SIGNUP_ENABLED

  # dependencies are here to keep karma happy
  # this prevents having to have a requires of *.coffee down through
  externalAccounts = hiddenRequire '../../backend/services/service.externalAccounts'
  cartodbConfig = hiddenRequire '../../backend/config/cartodb/cartodb'

  mapBoxPromise = externalAccounts.getAccountInfo('mapbox')
  .then (accountInfo) ->
    safeConfig.mapbox = accountInfo.api_key

  cartoDbPromise = cartodbConfig()
  .then (config) ->
    safeConfig.cartodb =
      TILE_URL: config.TILE_URL
      MAPS: []
    for map in config.MAPS
      safeConfig.cartodb.MAPS.push(name: map.name)

  googlePromise = externalAccounts.getAccountInfo('googlemaps', {quiet: true})
  .catch (err) ->
    null
  .then (accountInfo) ->
    safeConfig.google = accountInfo?.api_key ? null

  stripePromise = externalAccounts.getAccountInfo 'stripe'
  .then ({other}) ->
    if config.PAYMENT_PLATFORM.LIVE_MODE
      if config.ENV != 'production' && !config.ALLOW_LIVE_APIS
        throw new Error("Refusing to use stripe live API from #{config.ENV} -- set ALLOW_LIVE_APIS to force")
      safeConfig.stripe = other.public_live_api_key # ONLY public key should be set here!
    else
      safeConfig.stripe = other.public_test_api_key # ONLY public key should be set here!

  Promise.all [
    mapBoxPromise
    cartoDbPromise
    googlePromise
    stripePromise
  ]
  .then () ->
    safeConfig

module.exports = {
  safeConfigPromise: memoize.promise(safeConfigPromise, maxAge: 10*60*1000)
}
