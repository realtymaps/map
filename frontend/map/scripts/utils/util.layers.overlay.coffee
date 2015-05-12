httpSync = require './util.httpSync.coffee'
routes = require '../../../common/config/routes.backend.coffee'
pieUtil = require './util.piechart.coffee'

_overlays =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: "markercluster"
    visible: true
    layerOptions:
      maxClusterRadius: 100
      chunkedLoading: true
      showCoverageOnHover: false
      removeOutsideVisibleBounds: true
      iconCreateFunction: pieUtil.pieCreateFunction

  backendPriceCluster:
    name: 'Price Cluster'
    type: 'group'
    visible: true

  addresses:
    name: 'Addresses'
    type: 'group'
    visible: true



module.exports = ->
  #only call function post login
  try
    _cartodb = JSON.parse httpSync.get routes.config.cartodb
  catch

  if _cartodb?.MAPS?
    _cartodb.MAPS.forEach (map) ->
      _overlays[map.name] =
        visible: false
        name: map.name
        url:'http://{account}.cartodb.com/api/v1/map/{mapid}/{z}/{x}/{y}.png?api_key={apikey}'
        type: 'xyz'
        layerOptions:
          apikey: _cartodb.API_KEY
          account: _cartodb.ACCOUNT
          mapid: map.mapId
  _overlays
