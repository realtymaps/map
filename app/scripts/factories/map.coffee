app = require '../app.coffee'
require './baseGoogleMap.coffee'
###
  Our Main Map Implementation
###
routes = require '../../../common/config/routes.coffee'
require '../services/httpStatus.coffee'
encode = undefined

app.factory 'Map'.ourNs(), [
  'Logger'.ns(), '$http', '$timeout', '$q',
  'GoogleMapApi'.ns(), 'BaseGoogleMap'.ourNs(), 'HttpStatus'.ourNs()
  ($log, $http, $timeout, $q,
  GoogleMapApi, BaseGoogleMap, HttpStatus) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false
          map:
            bounds: {}
            markers: []

        $log.info $scope.map
        $log.info "map.center: #{$scope.map.center}"

        GoogleMapApi.then (maps) ->
          encode = maps.geometry.encoding.encodePath
          polys = require('../mocks/polylines.coffee')()
          console.info "Polys: #{polys}"
          maps.visualRefresh = true
          $scope.map.polygons = polys


      updateMarkers:(map) =>
        toEncode = _.map @scope.map.bounds, (b) ->
          new google.maps.LatLng b.latitude, b.longitude

        hash = encode toEncode

        $http.get("#{routes.county.root}?bounds=#{hash}")
        .then (data) =>
          @scope.map.markers = data.data
  ]
