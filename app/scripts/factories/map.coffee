app = require '../app.coffee'
require './baseGoogleMap.coffee'
require '../services/httpStatus.coffee'
qs = require 'qs'

encode = undefined
###
  Our Main Map Implementation
###
app.factory 'Map'.ourNs(), ['uiGmapLogger', '$timeout', '$q', '$rootScope', 'uiGmapGoogleMapApi',
  'BaseGoogleMap'.ourNs(),
  'HttpStatus'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(), 'LayerFormatters'.ourNs(), 'MainOptions'.ourNs(),
  'ParcelEnums'.ourNs(), 'uiGmapGmapUtil',
  ($log, $timeout, $q, $rootScope, GoogleMapApi, BaseGoogleMap,
    HttpStatus, Properties, Events, LayerFormatters, MainOptions,
    ParcelEnums, uiGmapUtil) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        GoogleMapApi.then (maps) =>
          encode = maps.geometry.encoding.encodePath
          maps.visualRefresh = true
          @scope.dragZoom.options = Map.getDragZoomOptions()

        $log.debug $scope.map
        $log.debug "map center: #{$scope.center}"

        @filters = ''
        @filterDrawPromise = false
        $rootScope.$watch('selectedFilters', @filter, true) #TODO, WHY ROOTSCOPE?
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false

          listingOptions:
            boxClass: 'custom-info-window'
          layers:
            parcels: []
            mlsListings: []
            listingDetail: undefined
            filterSummary: []
            drawnPolys: []

          drawUtil:
            draw: undefined
            isEnabled: false

          actions:
            closeListing: ->
              $scope.layers.listingDetail.show = false

            listing: (gMarker, eventname, model) ->
              #TODO: maybe use a show attribute not on the model (dangerous two-way back to the database)
              if $scope.layers.listingDetail
                $scope.layers.listingDetail.show = false
              model.show = true
              $scope.layers.listingDetail = model
              offset = $scope.formatters.layer.MLS.getWindowOffset($scope.gMap, $scope.layers.listingDetail)
              return unless offset
              _.extend $scope.listingOptions,
                pixelOffset: offset
                disableAutoPan: true

          formatters:
            layer: LayerFormatters

          dragZoom: {}
          changeZoom: (increment) ->
            $scope.zoom += increment
          doClusterMarkers: true

        @scope.$watch 'zoom', (newVal, oldVal) =>
          #if there is a change close the listing view
          #it keeps the map running better on zooming as the infobox doesn't seem to scale well
          @scope.layers.listingDetail.show = false if newVal isnt oldVal

        @subscribe()

      redraw: () =>
        if @scope.zoom > @scope.options.parcelsZoomThresh
          Properties.getParcelBase(@hash).then (data) =>
            @scope.layers.parcels = data.data
            @scope.layers.mlsListings = data.data
        else
          @scope.layers.parcels.length = 0
          @scope.layers.mlsListings.length = 0

        if @filters
          Properties.getFilterSummary(@hash, @filters).then (data) =>
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
        @hash = encode paths
        @redraw()

      #TODO: all filter stuff should be moved to a baseClass, helper class or to its own controller
      filter: (newFilters, oldFilters) =>
        if not newFilters and not oldFilters then return
        if @filterDrawPromise
          $timeout.cancel(@filterDrawPromise)
        @filterDrawPromise = $timeout(@filterImpl, MainOptions.filterDrawDelay)

      filterImpl: () =>
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
            layer = {} #this is when a layer is an object

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

    Map
]
