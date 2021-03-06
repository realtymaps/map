externalAccounts = require '../services/service.externalAccounts'
logger = require('./logger').spawn('googleMaps')


locals = {}
setLocals = (keyParam) ->
  locals.mapsSdkUrl = "//maps.google.com/maps/api/js?v=3#{keyParam}&libraries=places"

setLocals('')

module.exports =
  loadValues: () ->
    externalAccounts.getAccountInfo('googlemaps', quiet: true)
    .catch (err) ->
      null  # we expect to not necessarily get a value here
    .then (accountInfo) ->
      if accountInfo?.api_key?
        logger.debug("Setting GoogleMaps API key")
        setLocals("&key=#{accountInfo.api_key}")
      else
        logger.warn("Not using a GoogleMaps API key")
  locals: locals
