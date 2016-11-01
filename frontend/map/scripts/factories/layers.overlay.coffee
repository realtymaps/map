app = require '../app.coffee'
pieMarkerFactory = require '../utils/util.piechart.marker.coffee'
commonConfig = require '../../../../common/config/commonConfig.coffee'
analyzeValue = require '../../../../common/utils/util.analyzeValue.coffee'
mainOptions = require '../config/mainOptions.coffee'

_overlays =
  currentLocation:
    name: 'Current Location'
    type: 'group'
    visible: true

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
      iconCreateFunction: pieMarkerFactory.create

  saves:
    name: "#{mainOptions.map.naming.save.pluralAlt}"
    type: 'markercluster'
    visible: true
    layerOptions:
      disableClusteringAtZoom: commonConfig.map.options.zoomThresh.price + 1
      maxClusterRadius: 60
      chunkedLoading: true
      showCoverageOnHover: false
      removeOutsideVisibleBounds: true
      iconCreateFunction: pieMarkerFactory.createSaves


  favorites:
    name: "Favorites"
    type: 'markercluster'
    visible: true
    layerOptions:
      disableClusteringAtZoom: commonConfig.map.options.zoomThresh.price + 1
      maxClusterRadius: 60
      chunkedLoading: true
      showCoverageOnHover: false
      removeOutsideVisibleBounds: true
      iconCreateFunction: pieMarkerFactory.createSaves


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
  $http
  $log
  rmapsEventConstants
  $rootScope
  rmapsCartoDb
) ->
  $log = $log.spawn('util:layers:overlays')

  init = () ->

    $log.debug 'getting cartodb'

    rmapsCartoDb.init()
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

  {init}
