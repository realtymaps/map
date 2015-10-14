pieUtil = require './util.piechart.coffee'

_overlays =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: 'markercluster'
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

  notes:
    name: 'Notes'
    type: 'group'
    visible: true

module.exports = ($log) ->
  _cartodb = do require './util.cartodb.coffee'
  #only call function post login
  if _cartodb?.MAPS?
    _cartodb.MAPS.forEach (map) ->
      _overlays[map.name] =
        visible: false
        name: map.name
        url: _cartodb.TILE_URL
        type: 'xyz'
        layerOptions:
          apikey: _cartodb.API_KEY
          account: _cartodb.ACCOUNT
          mapid: map.mapId
          attribution: ''
          maxZoom: 21
  _overlays
