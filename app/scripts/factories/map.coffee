requires = './baseGoogleMap.coffee'

app = require '../app.coffee'
require './baseGoogleMap.coffee'
###
  Our Main Map Implementation
###
marks = require '../mocks/markers.coffee'
console.info "Marks: #{marks}"

app.factory 'Map'.ourNs(), [
  'Logger'.ns(), '$http', '$timeout', '$q',
  'GoogleMapApi'.ns(), 'BaseGoogleMap'.ourNs(), 'Limits'.ourNs(), 'User'.ourNs()
  ($log, $http, $timeout, $q,
  GoogleMapApi, BaseGoogleMap, Limits, User) ->
    $q.all([Limits,User])
    .then((data) ->
      mapOptions = data.reduce (prev,current) ->
        _.extend prev.map.options, current
      class Map extends BaseGoogleMap
        constructor: ($scope) ->
          window.angular.extend $scope,
            control: {}
            showTraffic: true
            showWeather: false
            map:
              options: mapOptions
              center:
                latitude: 45
                longitude: -73
              markers: marks
              zoom: 3
              dragging: false
              bounds: {}

          GoogleMapApi.then (maps) ->
            polys = require('../mocks/polylines.coffee')()
            console.info "Polys: #{polys}"
            maps.visualRefresh = true
            $scope.map.polygons = polys
    )
    .error (e) ->
      #display modal or oops sorry map can not be shown
  ]
