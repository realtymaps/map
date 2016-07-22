externalAccounts = require '../services/service.externalAccounts'
logger = require './logger'


locals = {}
setLocals = (keyParam) ->
  locals.mapsSdkUrl = "//maps.google.com/maps/api/js?v=3#{keyParam}&libraries=places"

setLocals('')

module.exports =
  loadValues: () ->
    externalAccounts.getAccountInfo('googlemaps')
    .catch (err) ->
      null  # we expect to not necessarily get a value here
    .then (accountInfo) ->
      if accountInfo?.api_key?
        logger.info("Setting GoogleMaps API key")
        setLocals("&key=#{accountInfo.api_key}")
      else
        logger.warn("Not using a GoogleMaps API key")
  locals: locals
