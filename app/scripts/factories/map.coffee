app = require '../app.coffee'
require './baseGoogleMap.coffee'
###
  Our Main Map Implementation
###
marks = require '../mocks/markers.coffee'

app.factory 'Map'.ourNs(), [
  'Logger'.ns(), '$http', '$timeout', '$q',
  'GoogleMapApi'.ns(), 'BaseGoogleMap'.ourNs(),
  ($log, $http, $timeout, $q,
  GoogleMapApi, BaseGoogleMap) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false
          map:
            bounds: {}
            markers: marks

        $log.info $scope.map
        $log.info "map.center: #{$scope.map.center}"
        GoogleMapApi.then (maps) ->
          polys = require('../mocks/polylines.coffee')()
          console.info "Polys: #{polys}"
          maps.visualRefresh = true
          $scope.map.polygons = polys
  ]
