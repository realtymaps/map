app = require '../app.coffee'
require './baseGoogleMap.coffee'
require '../services/httpStatus.coffee'
qs = require 'qs'

encode = undefined
###
  Our Main Map Implementation
###
app.factory 'Map'.ourNs(), ['Logger'.ourNs(), '$timeout', '$q', '$rootScope', 'uiGmapGoogleMapApi',
  'BaseGoogleMap'.ourNs(),
  'HttpStatus'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(), 'LayerFormatters'.ourNs(), 'MainOptions'.ourNs(),
  'ParcelEnums'.ourNs(), 'uiGmapGmapUtil', 'FilterManager'.ourNs(),
  ($log, $timeout, $q, $rootScope, GoogleMapApi, BaseGoogleMap,
    HttpStatus, Properties, Events, LayerFormatters, MainOptions,
    ParcelEnums, uiGmapUtil, FilterManager) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        self = @
        GoogleMapApi.then (maps) =>
          encode = maps.geometry.encoding.encodePath
          maps.visualRefresh = true
          @scope.dragZoom.options = Map.getDragZoomOptions()

        $log.debug $scope.map
        $log.debug "map center: #{JSON.stringify($scope.center)}"
        $log.debug "map zoom: #{JSON.stringify($scope.zoom)}"

        @filterSummaryHash = {}
        @filters = ''
        @filterDrawPromise = false
        $rootScope.$watch('selectedFilters', @filter, true) #TODO, WHY ROOTSCOPE?
        @scope.savedProperties = Properties.getSavedProperties()

        @scope = _.merge @scope,
          control: {}
          showTraffic: true
          showWeather: false
          showMarkers: true

          listingOptions:
            boxClass: 'custom-info-window'
            closeBoxDiv: ' '
#            closeBoxDiv: '<i" class="pull-right fa fa-close fa-3x" style="position: relative; cursor: pointer;"></i>'
          layers:
            parcels: []
            listingDetail: undefined
            filterSummary: []
            drawnPolys: []

          controls:
            parcel: {}

          drawUtil:
            draw: undefined
            isEnabled: false

          actions:
            closeListing: ->
              $scope.layers.listingDetail.show = false if $scope.layers.listingDetail?
            listing: (gMarker, eventname, model) ->
              #TODO: maybe use a show attribute not on the model (dangerous two-way back to the database)
              #model could be from parcel or from filter, but the end all be all data is in filter
              unless model.rm_status
                return if not $scope.layers?.filterSummary? or @filterSummaryHash?
                model = if _.has self.filterSummaryHash, model.rm_property_id then self.filterSummaryHash[model.rm_property_id] else null
              return unless model

              if $scope.layers.listingDetail
                $scope.layers.listingDetail.show = false
              model.show = true
              $scope.layers.listingDetail = model
              offset = $scope.formatters.layer.MLS.getWindowOffset($scope.gMap, $scope.layers.listingDetail)
              return unless offset
              _.extend $scope.listingOptions,
                pixelOffset: offset
                disableAutoPan: true

            listingEvents:
              mouseover: (gObject, eventname, model) ->
                $scope.actions.listing(gObject, eventname, model)
                return if gObject.labelClass?
                gObject.setOptions($scope.formatters.layer.Parcels.mouseOverOptions)

              mouseout: (gObject, eventname, model) ->
                $scope.actions.closeListing()
                return if gObject.labelClass?
                childModel = if model.model? then model else model: model #need to fix api inconsistencies on uiGmap (Markers vs Polygons events)
                gObject.setOptions($scope.formatters.layer.Parcels.optionsFromFill(childModel))

              dblclick: (gObject, eventname, model) ->
                return if gObject.labelClass?#its a marker
                saved = Properties.saveProperty(model)
                return unless saved
                saved.then ->
                  childModel = if model.model? then model else model: model #need to fix api inconsistencies on uiGmap (Markers vs Polygons events)
                  gObject.setOptions($scope.formatters.layer.Parcels.optionsFromFill(childModel))

          formatters:
            layer: LayerFormatters

          dragZoom: {}
          changeZoom: (increment) ->
            $scope.zoom += increment

        @scope.$watch 'zoom', (newVal, oldVal) =>
          #if there is a change close the listing view
          #it keeps the map running better on zooming as the infobox doesn't seem to scale well
          if @scope.layers.listingDetail?
            @scope.layers.listingDetail.show = false if newVal isnt oldVal

        @subscribe()

      redraw: =>
        if @scope.zoom > @scope.options.parcelsZoomThresh
          @scope.showMarkers = false
          Properties.getParcelBase(@hash, @mapState).then (data) =>
            @scope.layers.parcels = data.data
        else
          @scope.layers.parcels.length = 0
          @scope.showMarkers = true

        if @filters
          Properties.getFilterSummary(@hash, @filters, @mapState).then (data) =>
            return unless data?.data?
            @scope.layers.filterSummary = data.data
            @updateFilterSummaryHash()
        else
          @scope.layers.filterSummary.length = 0

      draw: (event, paths) =>

        if not paths and not @scope.drawUtil.isEnabled
          paths = _.map @scope.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        return if not paths? or not paths.length > 0

        @hash = encode paths
        @mapState = qs.stringify(center: @scope.center, zoom: @scope.zoom)
        @redraw()

      filter: (newFilters, oldFilters) =>
        if not newFilters and not oldFilters then return
        if @filterDrawPromise
          $timeout.cancel(@filterDrawPromise)
        @clearFilter()
        @filterDrawPromise = $timeout(=>
          @filters = FilterManager.manage =>
            @filterDrawPromise = false
            @redraw()
        , MainOptions.filterDrawDelay)

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

      updateFilterSummaryHash: =>
        @filterSummaryHash = {}
        _.defer =>
          @scope.layers.filterSummary.forEach (summary) =>
            @filterSummaryHash[summary.rm_property_id] = summary
          @scope.formatters.layer.updateFilterSummaryHash @filterSummaryHash

      clearFilter: =>
        @scope.layers.parcels.length = 0 #must clear so it is rebuilt!
        @scope.layers.filterSummary.length = 0
        @updateFilterSummaryHash()

    Map
]
