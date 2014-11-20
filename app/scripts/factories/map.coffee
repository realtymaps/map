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
  'uiGmapGoogleMapApi', 'BaseGoogleMap'.ourNs(), 'HttpStatus'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(),
  ($log, $timeout, $q, GoogleMapApi, BaseGoogleMap, HttpStatus, Properties, Events) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false
          map:
            drawPolys:
              draw: undefined
              polygons: []
              isEnabled: false
            window: undefined
            windowOptions:
              forceClick: true
            markers: []
            clickedMarker: (gMarker, eventname, model) ->
              $scope.map.window = model

        @subscribe()

        $log.info $scope.map
        $log.info "map.center: #{$scope.map.center}"

        GoogleMapApi.then (maps) ->
          encode = maps.geometry.encoding.encodePath
          maps.visualRefresh = true

      updateMarkers: (event, paths) =>
        if not paths and not @scope.map.drawPolys.isEnabled
          paths = _.map @scope.map.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        return if not paths? or not paths.length > 0

        hash = encode paths
        #query to county data, should be encapsulated in a service which has all the urls
        Properties.getCounty(hash).then (data) =>
          @scope.map.markers = data.data

        Properties.getParcelsPolys(hash).then (data) =>
          @scope.map.polygons = data.data.map (d) ->
            d.geom_polys = JSON.parse(d.geom_polys)
            d

      subscribe: ->
        #subscribing to events (Angular's built in channel bubbling)
        @scope.$onRootScope Events.map.drawPolys.clear, =>
          @scope.map.drawPolys.polygons = []

        @scope.$onRootScope Events.map.drawPolys.isEnabled, (event, isEnabled) =>
          @scope.map.drawPolys.isEnabled = isEnabled
          if isEnabled
            @scope.map.markers = []
            @scope.map.drawPolys.draw()

        @scope.$onRootScope Events.map.drawPolys.query, =>
          polygons = @scope.map.drawPolys.polygons
          paths = _.flatten polygons.map (polygon) ->
            _.reduce(polygon.getPaths().getArray()).getArray()
          @updateMarkers 'draw_tool', paths

]
