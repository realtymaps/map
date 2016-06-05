app = require '../app.coffee'
pieUtil = require './util.piechart.coffee'
commonConfig = require '../../../../common/config/commonConfig.coffee'
analyzeValue = require '../../../../common/utils/util.analyzeValue.coffee'

_overlays =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: 'markercluster'
    visible: true
    layerOptions:
      disableClusteringAtZoom: commonConfig.map.options.zoomThresh.price + 1
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

app.factory 'rmapsOverlays', (
  $http,
  $log,
  rmapsEventConstants,
  $rootScope
) ->
  $log = $log.spawn('util:layers:overlays')

  $log.debug 'getting cartodb'
  require('./util.cartodb.coffee')($http)
  .then (cartodb) ->
    $log.debug 'cartodb successful'
    #only call function post login
    if cartodb?.MAPS?
      cartodb.MAPS.forEach (map) ->
        _overlays[map.name] =
          visible: false
          name: map.name
          url: cartodb.TILE_URL
          type: 'xyz'
          layerOptions:
            apikey: cartodb.API_KEY
            account: cartodb.ACCOUNT
            mapid: map.mapId
            attribution: ''
            maxZoom: 21

    $log.debug 'cartodb merged into overlays'
    _overlays
  .catch (err) ->
    msgPart = analyzeValue err
    $rootScope.$emit rmapsEventConstants.alert.spawn, msg: "Overlays failed to load with error #{msgPart}."
