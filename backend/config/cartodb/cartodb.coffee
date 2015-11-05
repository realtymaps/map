_ = require 'lodash'
externalAccounts = require '../../services/service.externalAccounts'
require '../../config/promisify'
memoize = require 'memoizee'
Promise = require 'bluebird'


getConfig = () -> Promise.try () ->
  externalAccounts.getAccountInfo('cartodb')
  .then (accountInfo) ->
    root = "//#{accountInfo.username}.cartodb.com/api/v1"
    apiUrl = "api_key=#{accountInfo.api_key}"
    
    API_KEY: accountInfo.api_key
    ACCOUNT: accountInfo.username
    API_KEY_TO_US: accountInfo.other.api_key_to_us
    MAPS: accountInfo.other.maps
    TEMPLATE: null
    ROOT_URL: root
    API_URL: apiUrl
    TILE_URL: "#{root}/map/{mapid}/{z}/{x}/{y}.png?#{apiUrl}"
    WAKE_URLS: _.map(accountInfo.other.maps, (m) -> "#{root}/map/named/#{m.name}?#{apiUrl}")

module.exports = memoize.promise(getConfig, maxAge: 15*60*1000)
