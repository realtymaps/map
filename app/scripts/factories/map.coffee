app = require '../app.coffee'
qs = require 'qs'

encode = undefined
###
  Our Main Map Implementation
###
app.factory 'Map'.ourNs(), ['Logger'.ourNs(), '$timeout', '$q', '$rootScope', 'uiGmapGoogleMapApi',
  'BaseGoogleMap'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(), 'LayerFormatters'.ourNs(), 'MainOptions'.ourNs(),
  'ParcelEnums'.ourNs(), 'uiGmapGmapUtil', 'FilterManager'.ourNs(), 'ResultsFormatter'.ourNs(), 'ZoomLevel'.ourNs(),
  'GoogleService'.ourNs(), 'uiGmapPromise'
  ($log, $timeout, $q, $rootScope, GoogleMapApi, BaseGoogleMap,
    Properties, Events, LayerFormatters, MainOptions,
    ParcelEnums, uiGmapUtil, FilterManager, ResultsFormatter, ZoomLevel, GoogleService,
    uiGmapPromise) ->

    invokePropertyService = (mapFact, serviceName, cb) ->
      myId = mapFact.drawPromisesIndex += 1
      mapFact.drawPromisesMap.put myId,
      Properties[serviceName](mapFact.hash, mapFact.mapState, mapFact.filters)
      .then (data) =>
        cb(mapFact, data.data) if data?
      .finally =>
        mapFact.drawPromisesMap.remove myId

    getParcelBase = (mapFact) ->
      invokePropertyService mapFact, 'getParcelBase', (mapFact, data) ->
        mapFact.scope.layers.parcels = data
    getFilterSummary = (mapFact) ->
      invokePropertyService mapFact, 'getFilterSummary', (mapFact, data) ->
        return unless data?
        mapFact.scope.layers.filterSummary = data
        mapFact.updateFilterSummaryHash()

    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        # $scope.debug = true
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        $scope.zoomLevelService = ZoomLevel
        self = @
        @drawPromisesMap = new PropMap()
        @drawPromisesIndex = 0
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

        _maybeHideAddressMarker = (gObject) ->
          if ZoomLevel.isAddressParcel($scope.zoom)
            if $scope.addressMarkerHovered? and gObject != $scope.addressMarkerHovered
              $scope.addressMarkerHovered.setVisible(true)
          if ZoomLevel.isAddressParcel($scope.zoom) and GoogleService.Map.isGMarker(gObject)
            $scope.addressMarkerHovered = gObject
            gObject.setVisible(false)
            return true
          return false

        _updateGObjects = (gObject, savedDetails, childModel) ->
          #purpose to to take some sort of gObject and update its view immediately
          childModel.model.savedDetails = savedDetails
          if gObject.labelClass?
            opts = $scope.formatters.layer.MLS.markerOptionsFromForSale childModel.model
          else
            opts =  $scope.formatters.layer.Parcels.optionsFromFill(childModel)
          gObject.setOptions(opts) if opts
          $scope.resultsFormatter?.reset()

        _saveProperty = (gObject, childModel) ->
          #TODO: Need to debounce / throttle
          saved = Properties.saveProperty(childModel.model)
          return unless saved
          saved.then (savedDetails) ->
            #setting savedDetails here as we know the save was successful (update the font end without query right away)
            index = if childModel.model.index? then childModel.model.index else self.filterSummaryHash[childModel.model.rm_property_id]?.index
            if index? #only has index if there is a filter object
              match = self.scope.layers.filterSummary[index]
              match.savedDetails = savedDetails if match?

            #need to figure out a better way
            self.updateFilterSummaryHash()
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
                return if _maybeHideAddressMarker(gObject)
                $scope.actions.listing(gObject, eventname, model)
                return if gObject.labelClass?
                childModel = GoogleService.UiMap.getCorrectModel model
                opts = $scope.formatters.layer.Parcels.mouseOverOptions(childModel)
                gObject.setOptions opts

              mouseout: (gObject, eventname, model) ->
                $scope.actions.closeListing()
                return if gObject.labelClass?
                childModel = GoogleService.UiMap.getCorrectModel model
                opts = $scope.formatters.layer.Parcels.optionsFromFill(childModel)
                gObject.setOptions opts

              click: (gObject, eventname, model) ->
                #looks like google maps blocks ctrl down and click on gObjects (need to do super for windows (maybe meta?))
                #also esc/escape works with Meta ie press esc and it locks meta down. press esc again meta is off
                childModel = GoogleService.UiMap.getCorrectModel model
                return _saveProperty(gObject, childModel) if $scope.keys.ctrlIsDown or $scope.keys.cmdIsDown
                $scope.resultsFormatter.click(childModel.model)

              dblclick: (gObject, eventname, model) ->
                childModel = GoogleService.UiMap.getCorrectModel model
                _saveProperty gObject, childModel

          formatters:
            layer: LayerFormatters

          dragZoom: {}
          changeZoom: (increment) ->
            $scope.zoom += increment

        @scope.resultsFormatter = new ResultsFormatter(self)

        @scope.$watch 'zoom', (newVal, oldVal) =>
          #if there is a change close the listing view
          #it keeps the map running better on zooming as the infobox doesn't seem to scale well
          if @scope.layers.listingDetail?
            @scope.layers.listingDetail.show = false if newVal isnt oldVal

        @subscribe()

      clearBurdenLayers: =>
        if @gMap? and not ZoomLevel.isAddressParcel(@gMap,@scope) and not ZoomLevel.isParcel(@gMap)
          @scope.layers.parcels.length = 0

      redraw: =>
        if @drawPromisesMap.length
          @drawPromisesMap.each (p) ->
            p.cancel()

        if ZoomLevel.isAddressParcel(@scope.zoom, @scope) or ZoomLevel.isParcel(@scope.zoom)
          ZoomLevel.dblClickZoom.disable(@scope) if ZoomLevel.isAddressParcel(@scope.zoom)
          getParcelBase(@)
        else
          ZoomLevel.dblClickZoom.enable(@scope)
          @clearBurdenLayers()

        if @filters
          getFilterSummary(@)
        else
          @scope.layers.filterSummary.length = 0

      draw: (event, paths) =>
        @scope.resultsFormatter?.reset()
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
        @filterDrawPromise = $timeout =>
          FilterManager.manage (filters) =>
            @filters = filters
            @filterDrawPromise = false
            @redraw()
        , MainOptions.filterDrawDelay

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
          return if not @scope.layers.filterSummary or not @scope.layers.filterSummary.length
          @scope.layers.filterSummary.forEach (summary, index) =>
            summary.index = index
            @filterSummaryHash[summary.rm_property_id] = summary
          @scope.formatters.layer.updateFilterSummaryHash @filterSummaryHash

      clearFilter: =>
        @scope.layers.parcels.length = 0 #must clear so it is rebuilt!
        @scope.layers.filterSummary.length = 0
        @updateFilterSummaryHash()
]
