_ = require 'lodash'
externalAccounts = require '../../services/service.externalAccounts.coffee'
require '../../config/promisify.coffee'
memoize = require 'memoizee'
Promise = require 'bluebird'
request = require('request')
# coffeelint: disable=check_scope
logger = require('../logger').spawn("config:cartodb")
# coffeelint: enable=check_scope

getConfig = () -> Promise.try () ->
  externalAccounts.getAccountInfo('cartodb')
  .then (accountInfo) ->
    root = "//#{accountInfo.username}.cartodb.com/api/v1"
    apiUrl = "api_key=#{accountInfo.api_key}"
    mapPromises = []

    for key, mapId of accountInfo.other
      do ->
        if key.startsWith('map-')
          mapName = key.substr(4)
          mapPromises.push(
            Promise.promisify(request.post, {context: request, multiArgs: true})({
              url: "https:#{root}/map/named/#{mapName}?#{apiUrl}"
              headers: 'Content-Type': 'application/json;charset=utf-8'
            })
            .then ([result, body]) ->
              body = JSON.parse(body).layergroupid

            .catch (err) ->
              logger.debug err

            .then (layergroupid) ->
              name: mapName
              mapId: layergroupid || mapId
          )

    Promise.all(mapPromises).then (maps) ->

      cdn = process.env.CDN_HOST || 'parcels.realtymapsterllc.netdna-ssl.com'

      API_KEY: accountInfo.api_key
      ACCOUNT: accountInfo.username
      API_KEY_TO_US: accountInfo.other.api_key_to_us
      MAPS: maps
      TEMPLATE: null
      ROOT_URL: root
      TILE_URL: "//#{cdn}/api/tiles/{mapid}/{z}/{x}/{y}"
      WAKE_URLS: _.map(maps, (m) -> "#{root}/map/named/#{m.name}?#{apiUrl}")

module.exports = memoize.promise(getConfig, maxAge: 15*60*1000)
