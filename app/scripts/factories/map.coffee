app = require '../app.coffee'
require './baseGoogleMap.coffee'
require '../services/httpStatus.coffee'
qs = require 'qs'

encode = undefined
###
  Our Main Map Implementation
###
app.factory 'Map'.ourNs(), [
  'uiGmapLogger', '$timeout', '$q', '$rootScope',
  'uiGmapGoogleMapApi', 'BaseGoogleMap'.ourNs(),
  'HttpStatus'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(),
  'LayerFormatters'.ourNs(), 'ParcelEnums'.ourNs(),
  ($log, $timeout, $q, $rootScope,
    GoogleMapApi, BaseGoogleMap,
    HttpStatus, Properties, Events,
    LayerFormatters, ParcelEnums) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds

        @filters = ''
        # @filterDrawDelay is how long to wait when filters are modified to see if more modifications are incoming before querying
        #TODO: This should come from frontend config
        @filterDrawDelay = 1000

        @filterDrawPromise = false
        $rootScope.$watch('selectedFilters', @filter, true) #TODO, WHY ROOTSCOPE?
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false

          layers:
            parcels: []
            mlsListings: []
            listingDetail: undefined
            filterSummary: []
            drawnPolys: []

        #consider moving to layers
          drawUtil:
            draw: undefined
            isEnabled: false

          actions:
            listing: (gMarker, eventname, model) ->
              $scope.layers.listingDetail = model

          formatters:
            layer: LayerFormatters

          dragZoom: {}
          changeZoom: (increment) ->
            $scope.zoom += increment
          doClusterMarkers: true

        @subscribe()

        $log.debug $scope.map
        $log.debug "map center: #{$scope.center}"

        GoogleMapApi.then (maps) =>
          encode = maps.geometry.encoding.encodePath
          maps.visualRefresh = true
          @scope.dragZoom.options = getDragZoomOptions()

      redraw: (paths) =>
        hash = encode paths
        if @scope.zoom > @scope.options.parcelsZoomThresh
          Properties.getParcelBase(hash).then (data) =>
            @scope.layers.parcels = data.data
            @scope.layers.mlsListings = data.data
        else
          @scope.layers.parcels.length = 0
          @scope.layers.mlsListings.length = 0

        if @filters
          Properties.getFilterSummary(hash, @filters).then (data) =>
            @scope.layers.filterSummary = data.data
        else
          @scope.layers.filterSummary.length = 0

      draw: (event, paths) =>
        @scope.doClusterMarkers = if @scope.zoom < @scope.options.clusteringThresh then true else false

        if not paths and not @scope.drawUtil.isEnabled
          paths = _.map @scope.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        return if not paths? or not paths.length > 0

        oldDoCluster = @scope.doClusterMarkers

        @scope.layers.mlsListings = [] if oldDoCluster is not @scope.doClusterMarkers
        @redraw(paths)

      #TODO: all filter stuff should be moved to a baseClass, helper class or to its own controller
      filter: (newFilters, oldFilters) =>
        if not newFilters and not oldFilters then return
        if @filterDrawPromise
          $timeout.cancel(@filterDrawPromise)
        @filterDrawPromise = $timeout(@filterImpl, @filterDrawDelay)

      filterImpl: =>
        if $rootScope.selectedFilters
          selectedFilters = _.clone($rootScope.selectedFilters)
          selectedFilters.status = []
          if (selectedFilters.forSale)
            selectedFilters.status.push(ParcelEnums.status.forSale)
            delete selectedFilters.forSale
          if (selectedFilters.pending)
            selectedFilters.status.push(ParcelEnums.status.pending)
            delete selectedFilters.pending
          if (selectedFilters.sold)
            selectedFilters.status.push(ParcelEnums.status.recentlySold)
            delete selectedFilters.sold
          if selectedFilters.status.length == 0
            @filters = null
          else
            @filters = '&' + qs.stringify(selectedFilters)
        else
          @scope.layers.parcels.length = 0
          @scope.layers.mlsListings.length = 0

          @filters = null
        @filterDrawPromise = false
        @redraw()

      subscribe: ->
        #subscribing to events (Angular's built in channel bubbling)
        @scope.$onRootScope Events.map.drawPolys.clear, =>
          _.each @scope.layers, (layer, k) ->
            return layer.length = 0 if layer? and _.isArray layer
            layer = {}

        @scope.$onRootScope Events.map.drawPolys.isEnabled, (event, isEnabled) =>
          @scope.drawUtil.isEnabled = isEnabled
          if isEnabled
            @scope.layers.mlsListings.length = 0
            @scope.drawUtil.draw()

        @scope.$onRootScope Events.map.drawPolys.query, =>
          polygons = @scope.layers.drawnPolys
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
