app = require '../app.coffee'
require './baseGoogleMap.coffee'
###
  Our Main Map Implementation
###
require '../services/httpStatus.coffee'
encode = undefined

qs = require 'qs'


app.factory 'Map'.ourNs(), [
  'uiGmapLogger', '$timeout', '$q', '$rootScope',
  'uiGmapGoogleMapApi', 'BaseGoogleMap'.ourNs(),
  'HttpStatus'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(),
  'Parcels'.ourNs()
  ($log, $timeout, $q, $rootScope,
  GoogleMapApi, BaseGoogleMap,
  HttpStatus, Properties, Events,
  Parcels) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        $log.doLog = limits.options.doLog
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        @hash = ''
        @filters = ''
        # @filterDrawDelay is how long to wait when filters are modified to see if more modifications are incoming before querying
        @filterDrawDelay = 1000
        @filterDrawPromise = false
        $rootScope.$watch('selectedFilters', @filter, true)
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false
          map:
            polygons: []
            dragZoom:{}
            changeZoom: (increment) ->
              $scope.map.zoom += increment
            doClusterMarkers: true
            drawPolys:
              draw: undefined
              polygons: []
              isEnabled: false
            window: undefined
            windowOptions:
              forceClick: true
            markers: []
            parcels: Parcels
            labelFromParcel: (p) ->
              return {} unless p
              icon: ' '
              labelContent: p.street_num
              labelAnchor: "0 0"
              labelClass: "address-label"

            clickedMarker: (gMarker, eventname, model) ->
              $scope.map.window = model

        @subscribe()

        $log.info $scope.map
        $log.info "map.center: #{$scope.map.center}"

        GoogleMapApi.then (maps) =>
          encode = maps.geometry.encoding.encodePath
          maps.visualRefresh = true
          @scope.map.dragZoom.options = getDragZoomOptions()

      redraw: () =>
        if @scope.map.zoom > @scope.map.options.parcelsZoomThresh
          Properties.getCounty(hash).then (data) =>
            @scope.map.markers = data.data

          Properties.getParcelsPolys(hash).then (data) =>
            @scope.map.polygons = data.data
        else
          @scope.map.polygons.length = 0
          @scope.map.markers.length = 0
        
      draw: (event, paths) =>
        if not paths and not @scope.map.drawPolys.isEnabled
          paths = _.map @scope.map.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        return if not paths? or not paths.length > 0

        @hash = encode paths
        oldDoCluster = @scope.map.doClusterMarkers
        @scope.map.doClusterMarkers = if @map.zoom < @scope.map.options.clusteringThresh then true else false
        @scope.map.markers = [] if oldDoCluster is not @scope.map.doClusterMarkers

        @redraw()
      
      filter: (newFilters, oldFilters) =>
        if not newFilters and not oldFilters then return
        if @filterDrawPromise
          $timeout.cancel(@filterDrawPromise)
        @filterDrawPromise = $timeout(@filterImpl, @filterDrawDelay)
        
      filterImpl: () =>
        @filters = if $rootScope.selectedFilters then qs.stringify($rootScope.selectedFilters) else '' 
        @filters = '&'+@filters if @filters.length > 0
        @filterDrawPromise = false
        @redraw()
      
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
