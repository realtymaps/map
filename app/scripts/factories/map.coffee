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
          @scope.$watch 'bounds', (newVal, oldVal) =>
            if newVal
              @scope.searchbox.setBiasBounds()
          , true

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

        _saveProperty = (model, gObject) =>
          #TODO: Need to debounce / throttle
          saved = Properties.saveProperty(model)
          return unless saved
          saved.then (savedDetails) =>
            if @filterSummaryHash[model.rm_property_id]?
              @filterSummaryHash[model.rm_property_id].savedDetails = savedDetails
            if @lastHoveredModel?.rm_property_id == model.rm_property_id && !$scope.formatters.layer.isVisible(@filterSummaryHash[model.rm_property_id])
              $scope.actions.closeListing()
            #setting savedDetails here as we know the save was successful (update the font end without query right away)
            index = if model.index? then model.index else @filterSummaryHash[model.rm_property_id]?.index
            if index? #only has index if there is a filter object
              match = self.scope.layers.filterSummary[index]
              match.savedDetails = savedDetails if match?
              uiGmapControls.updateAllModels match
            #need to figure out a better way
            @updateFilterSummaryHash()
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
            listing: (gMarker, eventname, model) =>
              #model could be from parcel or from filter, but the end all be all data is in filter
              if !model.rm_status
                if !$scope.layers?.filterSummary? or !@filterSummaryHash?
                  return
                model = @filterSummaryHash?[model.rm_property_id] || model
              # so we don't show the window on un-saved properties
              if !$scope.formatters.layer.isVisible(model)
                return

              if $scope.layers.listingDetail
                $scope.layers.listingDetail.show = false
              model.show = true
              $scope.layers.listingDetail = model
              offset = $scope.formatters.layer.MLS.getWindowOffset(@gMap, $scope.layers.listingDetail)
              return unless offset
              _.extend $scope.listingOptions,
                pixelOffset: offset
                disableAutoPan: true

            listingEvents:
              mouseover: (gObject, eventname, model) =>
                $scope.actions.listing(gObject, eventname, model)
                model = GoogleService.UiMap.getCorrectModel model
                @lastHoveredModel = model
                model.isMousedOver = true
                if GoogleService.Map.isGMarker(gObject) && gObject.markerType == "price"
                  model.isMousedOver = true
                  @hovers[model.rm_property_id] = model
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

          #TODO: move ResultsFormatter into here as result for consistency
          formatters:
            layer: LayerFormatters

          dragZoom: {}
          changeZoom: (increment) ->
            $scope.zoom += increment
            
          searchbox:
            template: 'map-searchbox.tpl.html'
            parent: 'searchbox-container'
            options:
              bounds: {}
            events:
              places_changed: (searchBox) =>
                places = searchBox.getPlaces()
                if !places.length
                  return
                place = places[0]
                if (place.formatted_address)
                  document.getElementById('places-search-input').value = place.formatted_address
                if place.geometry?.viewport
                  @scope.bounds =
                    northeast:
                      latitude: place.geometry.viewport.getNorthEast().lat()
                      longitude: place.geometry.viewport.getNorthEast().lng()
                    southwest:
                      latitude: place.geometry.viewport.getSouthWest().lat()
                      longitude: place.geometry.viewport.getSouthWest().lng()
                else
                  @scope.center =
                    latitude: place.geometry.location.lat()
                    longitude: place.geometry.location.lng()
                  @scope.zoom = 19
            setBiasBounds: () =>
              sw = uiGmapUtil.getCoords(@scope.bounds?.southwest)
              sw ||= uiGmapUtil.getCoords(latitude: @scope.center.latitude-0.01, longitude: @scope.center.longitude-0.01)
              ne = uiGmapUtil.getCoords(@scope.bounds?.northeast)
              ne ||= uiGmapUtil.getCoords(latitude: @scope.center.latitude+0.01, longitude: @scope.center.longitude+0.01)
              @scope.searchbox.options.bounds = new google.maps.LatLngBounds(sw, ne)

        @scope.resultsFormatter = new ResultsFormatter(self)

        @scope.$watch 'zoom', (newVal, oldVal) =>
          #if there is a change close the listing view
          #it keeps the map running better on zooming as the infobox doesn't seem to scale well
          if @scope.layers.listingDetail?
            @scope.layers.listingDetail.show = false if newVal isnt oldVal

        @subscribe()
        uiGmapControls.init $scope.controls

      clearBurdenLayers: =>
        if @gMap? and not ZoomLevel.isAddressParcel(@gMap,@scope)
          @scope.layers.parcels.length = 0

      maybeShowGoogleParcelLines: =>
        if ZoomLevel.isParcel(@scope.zoom)
          return if @didAddGParcelLinesStyle
          @didAddGParcelLinesStyle = true
          @scope.options.styles.push @scope.formatters.layer.Parcels.style
        else
          if @didAddGParcelLinesStyle
            @scope.options.styles = _.without(@scope.options.styles, @scope.formatters.layer.Parcels.style)
            @didAddGParcelLinesStyle = false

      redraw: =>
        # something is funky about the way we're handling our data, and it's causing weird race conditions
        # so we're trying to avoid the races, and also using the control instead of the watched models
        # this is probably not the best setup either, but it's the best I could do without major refactors
        @waitToSetParcelData = true
        @waitingData = null

        @maybeShowGoogleParcelLines()
        if ZoomLevel.isAddressParcel(@scope.zoom, @scope)
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
          #TODO: newModels should not have to be used (yes it does fix a bug / race case)
          #using new models will cause a flicker as it erases and redraws all polys or markers
          if @waitingData
            @scope.controls.parcels.newModels @waitingData
            @waitingData = null
          else if ZoomLevel.isParcel(@scope.zoom) #we are just getting the bare min for parcels and using googles polylines
            @scope.controls.parcels.newModels data
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
