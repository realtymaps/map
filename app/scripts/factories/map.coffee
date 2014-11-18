app = require '../app.coffee'
require './baseGoogleMap.coffee'
require '../../styles/views/map.styl'
require '../../styles/views/toolbar.styl'
###
  Our Main Map Implementation
###
require '../services/httpStatus.coffee'
encode = undefined

app.factory 'Map'.ourNs(), [
  'uiGmapLogger', '$timeout', '$q',
  'uiGmapGoogleMapApi', 'BaseGoogleMap'.ourNs(), 'HttpStatus'.ourNs(), 'Properties'.ourNs(),
  ($log, $timeout, $q, GoogleMapApi, BaseGoogleMap, HttpStatus, Properties) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false
          map:
            drawPolys:
              polys: []
              isEnabled: false
            window: undefined
            windowOptions:
              forceClick: true
            markers: []
            clickedMarker: (gMarker, eventname, model) ->
              $scope.map.window = model

        $log.info $scope.map
        $log.info "map.center: #{$scope.map.center}"

        GoogleMapApi.then (maps) ->
          encode = maps.geometry.encoding.encodePath
          polys = require('../mocks/polylines.coffee')()
          console.info "Polys: #{polys}"
          maps.visualRefresh = true
          $scope.map.polygons = polys

      #subscribing to events (Angular's built in channel bubbling)
      @scope.$onRootScope events.map.drawPolys.clear, ->
        @scope.drawPolys.polys = []
      @scope.$onRootScope events.map.drawPolys.isEnabled, (isEnabled) ->
        @scope.drawPolys.isEnabled = isEnabled

      updateMarkers: (paths) =>
        unless paths
          paths = _.map @scope.map.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        hash = encode paths
        #query to county data, should be encapsulated in a service which has all the urls
        properties.getCounty(hash).then (data) =>
          @scope.map.markers = data.data
]
