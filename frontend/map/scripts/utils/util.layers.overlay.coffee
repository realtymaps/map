pieUtil = require './util.piechart.coffee'
# commonConfig = require '../../../../common/config/commonConfig'

_overlays =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: 'markercluster'
    visible: true
    layerOptions:
      disableClusteringAtZoom: 16 # commonConfig.map.options.zoomThresh.disableClusteringAtZoom
      maxClusterRadius: 60
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
    visible: false

  mail:
    name: 'Mail'
    type: 'group'
    visible: false

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
