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
        $scope.zoomLevelService = ZoomLevel
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
          if GoogleService.Map.isGMarker(gObject)
            opts = $scope.formatters.layer.MLS.markerOptionsFromForSale childModel.model
          else
            opts =  $scope.formatters.layer.Parcels.optionsFromFill(childModel)
          gObject.setOptions(opts) if opts
          $scope.resultsFormatter?.reset()

        _saveProperty = (childModel, gObject) ->
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
            return if GoogleService.Map.isGMarker(gObject) and ZoomLevel.isAddressParcel($scope.zoom)#dont change the color of the address marker
            _updateGObjects(gObject, savedDetails, childModel) if gObject

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

          controls: uiGmapControls

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
                #return if _maybeHideAddressMarker(gObject)
                $scope.actions.listing(gObject, eventname, model)
                return if gObject.labelClass?
                childModel = GoogleService.UiMap.getCorrectModel model
                opts = $scope.formatters.layer.Parcels.mouseOverOptions(childModel)
                gObject.setOptions opts

              mouseout: (gObject, eventname, model) ->
                if GoogleService.Map.isGPoly(gObject) || (GoogleService.Map.isGMarker(gObject) && gObject.markerType == "price")
                  $scope.actions.closeListing()
                return if gObject.labelClass?
                childModel = GoogleService.UiMap.getCorrectModel model
                opts = $scope.formatters.layer.Parcels.optionsFromFill(childModel)
                gObject.setOptions opts

              click: (gObject, eventname, model) ->
                #looks like google maps blocks ctrl down and click on gObjects (need to do super for windows (maybe meta?))
                #also esc/escape works with Meta ie press esc and it locks meta down. press esc again meta is off
                childModel = GoogleService.UiMap.getCorrectModel model
                return _saveProperty(childModel,gObject) if $scope.keys.ctrlIsDown or $scope.keys.cmdIsDown
                $scope.resultsFormatter.click(childModel.model)

              dblclick: (gObject, eventname, model, events) ->
                event = events[0]
                if event.stopPropagation then event.stopPropagation() else (event.cancelBubble=true)
                childModel = GoogleService.UiMap.getCorrectModel model
                _saveProperty childModel, gObject

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
              @scope.controls.parcels.newModels(data)
        else
          ZoomLevel.dblClickZoom.enable(@scope)
          @clearBurdenLayers()

        Properties.getFilterSummary(@hash, @mapState, @filters).then (data) =>
          return unless data?
          @scope.layers.filterSummary = data
          @updateFilterSummaryHash()
          if @waitingData
            @scope.controls.parcel.newModels(@waitingData)
            @waitingData = null
          @waitToSetParcelData = false
          @scope.$evalAsync () =>
            @scope.resultsFormatter?.reset()

      
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
