app = require '../app.coffee'
qs = require 'qs'

encode = undefined
###
  Our Main Map Implementation
###
app.factory 'Map'.ourNs(), ['Logger'.ourNs(), '$timeout', '$q', '$rootScope', 'uiGmapGoogleMapApi',
  'BaseGoogleMap'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(), 'LayerFormatters'.ourNs(), 'MainOptions'.ourNs(),
  'ParcelEnums'.ourNs(), 'uiGmapGmapUtil', 'FilterManager'.ourNs(), 'ResultsFormatter'.ourNs(),
  ($log, $timeout, $q, $rootScope, GoogleMapApi, BaseGoogleMap,
    Properties, Events, LayerFormatters, MainOptions,
    ParcelEnums, uiGmapUtil, FilterManager, ResultsFormatter) ->
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

        _updateGObjects = (gObject, savedDetails, childModel) ->
          #purpose to to take some sort of gObject and update its view immediately
          childModel.model.savedDetails = savedDetails
          if gObject.labelClass?
            opts = $scope.formatters.layer.MLS.markerOptionsFromForSale childModel.model
          else
            opts =  $scope.formatters.layer.Parcels.optionsFromFill(childModel)
          gObject.setOptions(opts) if opts
          $scope.resultsFormatter?.reset()

        _saveProperty = (gObject, model) ->
          #TODO: Need to debounce / throttle
          saved = Properties.saveProperty(model)
          return unless saved
          saved.then (savedDetails) ->
            childModel = if model.model? then model else model: model #need to fix api inconsistencies on uiGmap (Markers vs Polygons events)
            #setting savedDetails here as we know the save was successful (update the font end without query right away)
            _updateGObjects(gObject, savedDetails, childModel)

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

          keys:
            ctrlIsDown: false
            cmdIsDown: false

          actions:
            keyDown: (event) ->
              $scope.keys.ctrlIsDown = event.ctrlKey
              $scope.keys.cmdIsDown = event.keyIdentifier == 'Meta'
            keyUp: (event) ->
              $scope.keys.ctrlIsDown = event.ctrlKey
              $scope.keys.cmdIsDown = !(event.keyIdentifier == 'Meta')

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
              offset = $scope.formatters.layer.MLS.getWindowOffset(self.gMap, $scope.layers.listingDetail)
              return unless offset
              _.extend $scope.listingOptions,
                pixelOffset: offset
                disableAutoPan: true

            listingEvents:
              mouseover: (gObject, eventname, model) ->
                $scope.actions.listing(gObject, eventname, model)
                return if gObject.labelClass?
                childModel = if model.model? then model else model: model #need to fix api inconsistencies on uiGmap (Markers vs Polygons events)
                opts = $scope.formatters.layer.Parcels.mouseOverOptions(childModel)
                gObject.setOptions opts

              mouseout: (gObject, eventname, model) ->
                $scope.actions.closeListing()
                return if gObject.labelClass?
                childModel = if model.model? then model else model: model #need to fix api inconsistencies on uiGmap (Markers vs Polygons events)
                opts = $scope.formatters.layer.Parcels.optionsFromFill(childModel)
                gObject.setOptions opts

              click: (gObject, eventname, model) ->
                #looks like google maps blocks ctrl down and click on gObjects (need to do super for windows (maybe meta?))
                #also esc/escape works with Meta ie press esc and it locks meta down. press esc again meta is off
                _saveProperty(gObject, model) if $scope.keys.ctrlIsDown or $scope.keys.cmdIsDown

              dblclick: (gObject, eventname, model) ->
                _saveProperty gObject, model

          formatters:
            layer: LayerFormatters

          dragZoom: {}
          changeZoom: (increment) ->
            $scope.zoom += increment

        @scope.resultsFormatter = new ResultsFormatter($scope)

        @scope.$watch 'zoom', (newVal, oldVal) =>
          #if there is a change close the listing view
          #it keeps the map running better on zooming as the infobox doesn't seem to scale well
          if @scope.layers.listingDetail?
            @scope.layers.listingDetail.show = false if newVal isnt oldVal

        @subscribe()

      clearBurdenLayers: =>
        unless @gMap.getZoom() > @scope.options.parcelsZoomThresh
          @scope.layers.parcels.length = 0

      redraw: =>
        @scope.zoom > @scope.options.parcelsZoomThresh
        $timeout.cancel @allPromises if @allPromises

        promises  = []
        if @scope.zoom > @scope.options.parcelsZoomThresh
          unless @scope.options.disableDoubleClickZoom
            @scope.options = _.extend {}, @scope.options, disableDoubleClickZoom: true #new ref allows options watch to be kicked

          @scope.showMarkers = false
          promises.push Properties.getParcelBase(@hash, @mapState).then (data) =>
            @scope.layers.parcels = data.data
        else
          if @scope.options.disableDoubleClickZoom
            @scope.options = _.extend {}, @scope.options, disableDoubleClickZoom: false

          @clearBurdenLayers()
          @scope.showMarkers = true

        if @filters
          promises.push Properties.getFilterSummary(@hash, @filters, @mapState).then (data) =>
            return unless data?.data?
            @scope.layers.filterSummary = data.data
            @updateFilterSummaryHash()
        else
          @scope.layers.filterSummary.length = 0

        @allPromises = $q.all(promises).finally ->
          $rootScope.isLoading = false

      draw: (event, paths) =>
        $rootScope.isLoading = true
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
          FilterManager.manage (filters) =>
            @filters = filters
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
