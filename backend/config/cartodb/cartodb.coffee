_ = require 'lodash'
externalAccounts = require '../../services/service.externalAccounts.coffee'
require '../../config/promisify.coffee'
memoize = require 'memoizee'
Promise = require 'bluebird'


getConfig = () -> Promise.try () ->
  externalAccounts.getAccountInfo('cartodb')
  .then (accountInfo) ->
    root = "//#{accountInfo.username}.cartodb.com/api/v1"
    apiUrl = "api_key=#{accountInfo.api_key}"
    maps = []
    for key,val of accountInfo.other
      if key.startsWith('map-')
        maps.push(name: key.substr(4), mapId: val)

    API_KEY: accountInfo.api_key
    ACCOUNT: accountInfo.username
    API_KEY_TO_US: accountInfo.other.api_key_to_us
    MAPS: maps
    TEMPLATE: null
    ROOT_URL: root
    API_URL: apiUrl
    TILE_URL: "#{root}/map/{mapid}/{z}/{x}/{y}.png"
    WAKE_URLS: _.map(maps, (m) -> "#{root}/map/named/#{m.name}?#{apiUrl}")

module.exports = memoize.promise(getConfig, maxAge: 15*60*1000)
