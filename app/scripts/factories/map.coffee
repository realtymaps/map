app = require '../app.coffee'
require './baseGoogleMap.coffee'
require '../services/httpStatus.coffee'
qs = require 'qs'
encode = undefined
###
  Our Main Map Implementation
###
app.factory 'Map'.ourNs(), ['uiGmapLogger', '$timeout', '$q', '$rootScope', 'uiGmapGoogleMapApi', 'BaseGoogleMap'.ourNs(),
  'HttpStatus'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(), 'LayerFormatters'.ourNs(), 'MainOptions'.ourNs()
  ($log, $timeout, $q, $rootScope, GoogleMapApi, BaseGoogleMap, HttpStatus, Properties, Events, LayerFormatters, MainOptions) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds

        @filters = ''
        @filterDrawPromise = false
        $rootScope.$watch('selectedFilters', @filter, true) #TODO, WHY ROOTSCOPE?
        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false

          #consider moving to layers
          drawPolys:
            draw: undefined
            polygons: []
            isEnabled: false

          filterSummary: []
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

      redraw: (paths) =>
        if @scope.zoom > @scope.options.parcelsZoomThresh
          hash = encode paths
          Properties.getParcelBase(hash).then (data) =>
            @scope.layers.parcels = data.data
            #@scope.layers.mlsListings = data.data
        else
          @scope.layers.parcels.length = 0
          #@scope.layers.mlsListings .length = 0

        if @filters
          Properties.getFilterSummary(hash, @filters).then (data) =>
            @scope.filterSummary = data.data
        else
          @scope.filterSummary.length = 0

      draw: (event, paths) =>
        if not paths and not @scope.drawPolys.isEnabled
          paths = _.map @scope.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        return if not paths? or not paths.length > 0

        oldDoCluster = @scope.doClusterMarkers
        @scope.doClusterMarkers = if @scope.zoom < @scope.options.clusteringThresh then true else false
        @scope.layers.mlsListings = [] if oldDoCluster is not @scope.doClusterMarkers
        @redraw(paths)
      
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
            @filters = '&'+qs.stringify(selectedFilters)
        else
          @scope.layers.parcels.length = 0
          @scope.layers.mlsListings.length = 0

          @filters = null
        @filterDrawPromise = false
        @redraw()
      
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
