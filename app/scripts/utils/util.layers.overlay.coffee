httpSync = require './util.httpSync.coffee'
routes = require '../../../common/config/routes.backend.coffee'
_cartodb = JSON.parse httpSync.get routes.config.cartodb

_overlays =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: "markercluster"
    visible: true
    layerOptions:
      chunkedLoading: true
      showCoverageOnHover: false
      removeOutsideVisibleBounds: true

  backendPriceCluster:
    name: 'Price Cluster'
    type: 'group'
    visible: true

  addresses:
    name: 'Addresses'
    type: 'group'
    visible: true


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

module.exports = _overlays
