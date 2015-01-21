app = require '../app.coffee'
qs = require 'qs'
backendRoutes = require '../../../common/config/routes.backend.coffee'
analyzeValue = require '../../../common/utils/util.analyzeValue.coffee'

encode = undefined
###
  Our Main Map Implementation
###
app.factory 'Map'.ourNs(), ['Logger'.ourNs(), '$timeout', '$q', '$rootScope', 'uiGmapGoogleMapApi',
  'BaseGoogleMap'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(), 'LayerFormatters'.ourNs(), 'MainOptions'.ourNs(),
  'ParcelEnums'.ourNs(), 'uiGmapGmapUtil', 'FilterManager'.ourNs(), 'ResultsFormatter'.ourNs(), 'ZoomLevel'.ourNs(),
  'GoogleService'.ourNs(), 'uiGmapPromise', 'uiGmapControls'.ourNs(),
  ($log, $timeout, $q, $rootScope, GoogleMapApi, BaseGoogleMap,
    Properties, Events, LayerFormatters, MainOptions,
    ParcelEnums, uiGmapUtil, FilterManager, ResultsFormatter, ZoomLevel, GoogleService,
    uiGmapPromise, uiGmapControls) ->
    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        $scope.Toggles = limits.toggles

        $scope.zoomLevelService = ZoomLevel
        self = @

        GoogleMapApi.then (maps) =>
          encode = maps.geometry.encoding.encodePath
          maps.visualRefresh = true
          @scope.dragZoom.options = Map.getDragZoomOptions()

        $log.debug $scope.map
        $log.debug "map center: #{JSON.stringify($scope.center)}"
        $log.debug "map zoom: #{JSON.stringify($scope.zoom)}"

        #seems to be a google bug where mouse out is not always called
        @hovers = {}
        _cleanHovers = _.debounce =>
          $scope.$evalAsync =>
            for own rm_property_id, model of @hovers
              if @lastHoveredModel?.rm_property_id == rm_property_id
                continue
              model.isMousedOver = undefined
              _updateAllLayersByModel(model)
              delete @hovers[rm_property_id]
        _maybeCleanHovers = (model) =>
          keys = _.keys(@hovers)
          if keys.length > 1 || keys.length == 1 && keys[0] != model.rm_property_id
            _cleanHovers()

        @filterSummaryHash = {}
        @filters = ''
        @filterDrawPromise = false
        $rootScope.$watch('selectedFilters', @filter, true)
        @scope.savedProperties = Properties.getSavedProperties()

        _updateGObjects = (gObject, savedDetails, model) ->
          #purpose to to take some sort of gObject and update its view immediately
          model.savedDetails = savedDetails
          if GoogleService.Map.isGMarker(gObject)
            opts = $scope.formatters.layer.MLS.markerOptionsFromForSale model
          else
            opts =  $scope.formatters.layer.Parcels.optionsFromFill(model)
          gObject.setOptions(opts) if opts
          $scope.resultsFormatter?.reset()

        @updateAllLayersByModel = _updateAllLayersByModel = (model) ->
          uiGmapControls.eachSpecificGObject model.rm_property_id, (gObject) ->
            opts = if GoogleService.Map.isGMarker(gObject) then $scope.formatters.layer.MLS.markerOptionsFromForSale(model)
            else $scope.formatters.layer.Parcels.optionsFromFill(model)
            gObject.setOptions opts
          , ['streetNumMarkers']

        _saveProperty = (model, gObject) ->
          #TODO: Need to debounce / throttle
          saved = Properties.saveProperty(model)
          return unless saved
          saved.then (savedDetails) ->
            #setting savedDetails here as we know the save was successful (update the font end without query right away)
            index = if model.index? then model.index else self.filterSummaryHash[model.rm_property_id]?.index
            if index? #only has index if there is a filter object
              match = self.scope.layers.filterSummary[index]
              match.savedDetails = savedDetails if match?
              uiGmapControls.updateAllModels match
            #need to figure out a better way
            self.updateFilterSummaryHash()
            _updateAllLayersByModel model # need this here for immediate coloring of the parcel
            return if GoogleService.Map.isGMarker(gObject) and ZoomLevel.isAddressParcel($scope.zoom)#dont change the color of the address marker
            if gObject
              _updateGObjects(gObject, savedDetails, model)

        @saveProperty = _saveProperty

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
            parcels: {}
            streetNumMarkers: {}
            priceMarkers: {}

          drawUtil:
            draw: undefined
            isEnabled: false

          keys:
            ctrlIsDown: false
            cmdIsDown: false

          actions:

            closeListing: ->
              $scope.layers.listingDetail.show = false if $scope.layers.listingDetail?
            listing: (gMarker, eventname, model) ->
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
              mouseover: (gObject, eventname, model) =>
                $scope.actions.listing(gObject, eventname, model)
                model = GoogleService.UiMap.getCorrectModel model
                if GoogleService.Map.isGPoly(gObject)
                  model.isMousedOver = true
                if GoogleService.Map.isGMarker(gObject) && gObject.markerType == "price"
                  model.isMousedOver = true
                  @hovers[model.rm_property_id] = model
                  @lastHoveredModel = model
                  _maybeCleanHovers(model)
                _updateAllLayersByModel(model)

              mouseout: (gObject, eventname, model) =>
                model = GoogleService.UiMap.getCorrectModel model
                if GoogleService.Map.isGPoly(gObject) || (GoogleService.Map.isGMarker(gObject) && gObject.markerType == "price")
                  $scope.actions.closeListing()
                  model.isMousedOver = undefined
                  delete @hovers[model.rm_property_id]
                _updateAllLayersByModel(model)

              click: (gObject, eventname, model) =>
                #looks like google maps blocks ctrl down and click on gObjects (need to do super for windows (maybe meta?))
                #also esc/escape works with Meta ie press esc and it locks meta down. press esc again meta is off
                model = GoogleService.UiMap.getCorrectModel model
                event = window.event
                if event.ctrlKey or event.metaKey
                  return _saveProperty(model, gObject)
                $scope.resultsFormatter.click(@filterSummaryHash[model.rm_property_id]||model)

              dblclick: (gObject, eventname, model, events) ->
                event = events[0]
                if event.stopPropagation then event.stopPropagation() else (event.cancelBubble=true)
                model = GoogleService.UiMap.getCorrectModel model
                _saveProperty model, gObject

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
        uiGmapControls.init $scope.controls

      clearBurdenLayers: =>
        if @gMap? and not ZoomLevel.isAddressParcel(@gMap,@scope) and not ZoomLevel.isParcel(@gMap)
          @scope.layers.parcels.length = 0

      redraw: =>
        # something is funky about the way we're handling our data, and it's causing weird race conditions
        # so we're trying to avoid the races, and also using the control instead of the watched models
        # this is probably not the best setup either, but it's the best I could do without major refactors
        @waitToSetParcelData = true
        @waitingData = null
        if ZoomLevel.isAddressParcel(@scope.zoom, @scope) or ZoomLevel.isParcel(@scope.zoom)
          ZoomLevel.dblClickZoom.disable(@scope) if ZoomLevel.isAddressParcel(@scope.zoom)
          Properties.getParcelBase(@hash, @mapState).then (data) =>
            return unless data?
            if @waitToSetParcelData
              @waitingData = data
            else
              @scope.layers.parcels = data
        else
          ZoomLevel.dblClickZoom.enable(@scope)
          @clearBurdenLayers()

        Properties.getFilterSummary(@hash, @mapState, @filters).then (data) =>
          return unless data?
          @scope.layers.filterSummary = data
          @updateFilterSummaryHash()
          if @waitingData
            @scope.controls.parcels.newModels @waitingData
            @waitingData = null
          @waitToSetParcelData = false
          @scope.$evalAsync () =>
            @scope.resultsFormatter?.reset()

      
      draw: (event, paths) =>
        @scope.resultsFormatter?.reset()
        if not paths and not @scope.drawUtil.isEnabled
          paths = _.map @scope.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        return if not paths? or not paths.length > 1

        @hash = encode paths
        @mapState = qs.stringify(center: @scope.center, zoom: @scope.zoom, toggles: @scope.Toggles)
        @redraw()

      filter: (newFilters, oldFilters) =>
        if not newFilters and not oldFilters then return
        if @filterDrawPromise
          $timeout.cancel(@filterDrawPromise)
        @clearFilter()
        @filterDrawPromise = $timeout =>
          FilterManager.manage (@filters) =>
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
        if @scope.layers?.filterSummary? or @scope.layers.filterSummary.length
          @scope.layers.filterSummary.forEach (summary, index) =>
            summary.index = index
            @filterSummaryHash[summary.rm_property_id] = summary
        #need to always sync the formatters.layer hash
        @scope.formatters.layer.updateFilterSummaryHash @filterSummaryHash

      clearFilter: =>
        @scope.layers.parcels.length = 0 #must clear so it is rebuilt!
        @scope.layers.filterSummary.length = 0
        @updateFilterSummaryHash()
]
