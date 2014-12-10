app = require '../app.coffee'
require './baseGoogleMap.coffee'
###
  Our Main Map Implementation
###
require '../services/httpStatus.coffee'
# require '../services/parcels.coffee'
encode = undefined

app.factory 'Map'.ourNs(), [
  'uiGmapLogger', '$timeout', '$q',
  'uiGmapGoogleMapApi', 'BaseGoogleMap'.ourNs(),
  'HttpStatus'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(),
  'LayerFormatters'.ourNs()
  ($log, $timeout, $q,
  GoogleMapApi, BaseGoogleMap,
  HttpStatus, Properties, Events,
    LayerFormatters) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        $log.doLog = limits.options.doLog
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false

          #consider moving to layers
          drawPolys:
            draw: undefined
            polygons: []
            isEnabled: false

          layers:
            parcels: []
            mlsListings: []
            listingDetail: undefined

          layerFormatters: LayerFormatters

          dragZoom:{}
          changeZoom: (increment) ->
            $scope.zoom += increment
          doClusterMarkers: true

          clickedMarker: (gMarker, eventname, model) ->
            $scope.layers.listingDetail = model

        @subscribe()

        $log.debug $scope.map
        $log.debug "map center: #{$scope.center}"

        GoogleMapApi.then (maps) =>
          encode = maps.geometry.encoding.encodePath
          maps.visualRefresh = true
          @scope.dragZoom.options = getDragZoomOptions()

      draw: (event, paths) =>
        if not paths and not @scope.drawPolys.isEnabled
          paths = _.map @scope.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        return if not paths? or not paths.length > 0

        hash = encode paths
        oldDoCluster = @scope.doClusterMarkers
        @scope.doClusterMarkers = if @map.zoom < @scope.options.clusteringThresh then true else false
        @scope.layers.mlsListings = [] if oldDoCluster is not @scope.doClusterMarkers

#        $log.debug "current zoom: " + @scope.zoom

        if @scope.zoom > @scope.options.parcelsZoomThresh

          Properties.getParcelsPolys(hash).then (data) =>
            @scope.layers.parcels = data.data

          Properties.getMLS(hash).then (data) =>
              @scope.layers.mlsListings = data.data
        else
          @scope.layers.parcels.length = 0
          @scope.layers.mlsListings.length = 0

      subscribe: ->
        #subscribing to events (Angular's built in channel bubbling)
        @scope.$onRootScope Events.map.drawPolys.clear, =>
          @scope.drawPolys.polygons = []

        @scope.$onRootScope Events.map.drawPolys.isEnabled, (event, isEnabled) =>
          @scope.drawPolys.isEnabled = isEnabled
          if isEnabled
            @scope.layers.mlsListings.length = 0
            @scope.drawPolys.draw()

        @scope.$onRootScope Events.map.drawPolys.query, =>
          polygons = @scope.drawPolys.polygons
          paths = _.flatten polygons.map (polygon) ->
            _.reduce(polygon.getPaths().getArray()).getArray()
          @draw 'draw_tool', paths

    getDragZoomOptions = ->
      visualEnabled: true,
      visualPosition: google.maps.ControlPosition.LEFT,
      visualPositionOffset: new google.maps.Size(25, 425),
      visualPositionIndex: null,
      #TODO: change this image, DAN?
      visualSprite: "http://maps.gstatic.com/mapfiles/ftr/controls/dragzoom_btn.png",
      visualSize: new google.maps.Size(20, 20),
      visualTips:
        off: "Turn on",
        on: "Turn off"
    Map
]
