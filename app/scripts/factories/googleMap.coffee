requires = './baseGoogleMap.coffee'

app = require '../app.coffee'
###
  Our Main Map Implementation
###
#app.factory 'GoogleMap'.ourNs(), ['$scope', 'Logger'.ns(), '$http', '$timeout', ' GoogleMapApi'.ns(), 'BaseGoogleMap'.ourNs(),
module.exports = ($scope, $log, $http, $timeout, GoogleMapApi, BaseGoogleMap) ->
      #turn on ui-gmap's logger
      $log.doLog = true
      window.angular.extend($scope,
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
          markers: require '../mocks/markers.coffee'
          zoom: 3
          dragging: false
          bounds: {}

      )

      GoogleMapApi.then (maps) ->
        maps.visualRefresh = true
        $scope.map.polylines = require('../mocks/polylines.coffee')()
#  ]