requires = './baseGoogleMap.coffee'

app = require '../app.coffee'
require './baseGoogleMap.coffee'
###
  Our Main Map Implementation
###
marks = require '../mocks/markers.coffee'
console.info "Marks: #{marks}"

app.factory 'GoogleMap'.ourNs(), ['Logger'.ns(), '$http', '$timeout', 'GoogleMapApi'.ns(), 'BaseGoogleMap'.ourNs(),
  ($log, $http, $timeout, GoogleMapApi, BaseGoogleMap) ->
    class Map extends BaseGoogleMap
      constructor: ($scope) ->
        #turn on ui-gmap's logger
        $log.doLog = true
        window.angular.extend $scope,
          control: {}
          showTraffic: true
          showWeather: false
          map:
            center:
              latitude: 45
              longitude: -73
            options:
              streetViewControl: false
              panControl: false
              maxZoom: 20
              minZoom: 3
            markers: marks
            zoom: 3
            dragging: false
            bounds: {}

        GoogleMapApi.then (maps) ->
          polys = require('../mocks/polylines.coffee')()
          console.info "Polys: #{polys}"
          maps.visualRefresh = true
          $scope.map.polygons = polys
]