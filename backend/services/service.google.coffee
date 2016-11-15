Promise = require 'bluebird'
logger = require('../config/logger').spawn('service:google')
externalAccounts = require './service.externalAccounts'
google = require '@google/maps'

# get a promised api key that is allowed to talk to backend google services
# usually the map API key is restricted to browsers only
backendApiKey = () ->
  if process.env.GOOGLE_MAPS_BACKEND_API_KEY?
    logger.debug -> "using process.env.GOOGLE_MAPS_BACKEND_API_KEY"
    Promise.resolve api_key: process.env.GOOGLE_MAPS_BACKEND_API_KEY
  else
    logger.debug -> "using external accounts googlemaps_geocoding"
    externalAccounts.getAccountInfo('googlemaps_backend')

getGoogleClient = ({api} = {}) ->
  backendApiKey().then ({api_key}) ->
    client = google.createClient({
      Promise
      key: api_key
    })

    if !api?
      return client

    client[api]


module.exports = {
  getGoogleClient
  backendApiKey
}
