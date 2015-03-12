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
  'GoogleService'.ourNs(), 'uiGmapPromise', 'uiGmapControls'.ourNs(), 'uiGmapObjectIterators',
  ($log, $timeout, $q, $rootScope, GoogleMapApi, BaseGoogleMap,
    Properties, Events, LayerFormatters, MainOptions,
    ParcelEnums, uiGmapUtil, FilterManager, ResultsFormatter, ZoomLevel, GoogleService,
    uiGmapPromise, uiGmapControls, uiGmapObjectIterators) ->

    _initToggles = ($scope, toggles) ->
      _handleMoveToMyLocation = (position) ->
        unless position
          position =
            coords: $scope.previousCenter
        $scope.center = position.coords
        $scope.$evalAsync()

      toggles.setLocationCb(_handleMoveToMyLocation)
      $scope.Toggles = toggles

    class Map extends BaseGoogleMap
      constructor: ($scope, limits) ->
        super $scope, limits.options, limits.zoomThresholdMilliSeconds
        _initToggles $scope, limits.toggles

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

          _firstCenter = true
          @scope.$watchCollection 'center', (newVal, oldVal) =>
            if newVal != oldVal
              if _firstCenter
                _firstCenter = false
                return
              @scope.previousCenter = oldVal
              @scope.Toggles.hasPreviousLocation = true
            else
              @scope.Toggles.hasPreviousLocation = false

          @scope.satMap =
            options: _.extend mapTypeId: google.maps.MapTypeId.SATELLITE, self.scope.options
            bounds: {}
            zoom: 20
            control: {}
            init: ->
              $timeout ->
                gSatMap = self.scope.satMap.control.getGMap()
                google.maps.event.trigger(gSatMap, 'resize')
              , 500

        @singleClickCtrForDouble = 0
        $log.debug $scope.map
        $log.debug "map center: #{JSON.stringify($scope.center)}"
        $log.debug "map zoom: #{JSON.stringify($scope.zoom)}"

        #seems to be a google bug where mouse out is not always called
        _handleMouseout = (model) =>
          if !model
            return
          $scope.actions.closeListing()
          model.isMousedOver = undefined
          $timeout.cancel(@mouseoutDebounce)
          @mouseoutDebounce = null
          $scope.formatters.results.mouseleave(null, model)
        @mouseoutDebounce = null

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
          $scope.formatters.results?.reset()

        @updateAllLayersByModel = _updateAllLayersByModel = (model) ->
          uiGmapControls.eachSpecificGObject model.rm_property_id, (gObject) ->
            if GoogleService.Map.isGMarker(gObject)
              opts = $scope.formatters.layer.MLS.markerOptionsFromForSale(model)
            else
              opts = $scope.formatters.layer.Parcels.optionsFromFill(model)
            gObject.setOptions opts
          , ['streetNumMarkers']

        _isModelInFilterSummary = (model) ->
          model.index?

        # BEGIN POSSIBLE PropertySave SERVICE
        _maybeRemoveFilterSummaryObjects = (savedDetails, model) =>
          isEmptysFilterCanErase = !@filters and !savedDetails.isSaved

          if isEmptysFilterCanErase
            model.isMousedOver = undefined
            delete @scope.layers.filterSummary[model.rm_property_id]
            @scope.layers.filterSummary.length -= 1

        _maybeRefreshFilterSummary = (savedDetails, model) =>
          if savedDetails.isSaved and !_isModelInFilterSummary(model)
            @redraw(cache = false)

        _saveProperty = (model, gObject) =>
          #TODO: Need to debounce / throttle
          saved = Properties.saveProperty(model)
          return unless saved
          saved.then (savedDetails) =>
            #setting savedDetails here as we know the save was successful
            if @scope.layers.filterSummary[model.rm_property_id]?
              @scope.layers.filterSummary[model.rm_property_id].savedDetails = savedDetails

            if @lastHoveredModel?.rm_property_id == model.rm_property_id and
            !$scope.formatters.layer.isVisible(@scope.layers.filterSummary[model.rm_property_id])
              $scope.actions.closeListing()


            match = @scope.layers.filterSummary[model.rm_property_id]
            match.savedDetails = savedDetails if match?
            uiGmapControls.updateAllModels match

            _maybeRemoveFilterSummaryObjects(savedDetails, model)
            _maybeRefreshFilterSummary(savedDetails,model)

            _updateAllLayersByModel model # need this here for immediate coloring of the parcel
            return if GoogleService.Map.isGMarker(gObject) and ZoomLevel.isAddressParcel($scope.zoom)#dont change the color of the address marker
            if gObject
              _updateGObjects(gObject, savedDetails, model)
        # END POSSIBLE PropertySave SERVICE

        @saveProperty = _saveProperty
        #BEGIN SCOPE EXTENDING /////////////////////////////////////////////////////////////////////////////////////////
        @scope = _.merge @scope,
          streetViewPanorama:
            status: 'OK'
          control: {}
          showTraffic: true
          showWeather: false
          showMarkers: true

          listingOptions:
            boxClass: 'custom-info-window'
            closeBoxDiv: ' '

          layers:
            parcels: {}
            filterSummary: {}
            listingDetail: undefined
            drawnPolys: []

          controls:
            parcels: {}
            satParcels: {}
            streetNumMarkers: {}
            priceMarkers: {}
            streetView: {}

          drawUtil:
            draw: undefined
            isEnabled: false

          actions:

            closeListing: ->
              $scope.layers.listingDetail?.show = false
            listing: (gMarker, eventname, model) =>
              #model could be from parcel or from filter, but the end all be all data is in filter
              if !model.rm_status
                if !$scope.layers?.filterSummary?.length
                  return
                model = @$scope.layers.filterSummary?[model.rm_property_id] || model
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
                if GoogleService.Map.isGMarker(gObject) && gObject.markerType == "streetNum"
                  return
                model = GoogleService.UiMap.getCorrectModel model
                _lastHoveredModel = @lastHoveredModel
                @lastHoveredModel = model
                model.isMousedOver = true
                $timeout.cancel(@mouseoutDebounce)
                @mouseoutDebounce = null
                if _lastHoveredModel?.rm_property_id != model.rm_property_id
                  _handleMouseout(_lastHoveredModel)
                $scope.actions.listing(gObject, eventname, model)
                $scope.formatters.results.mouseenter(null, model)

              mouseout: (gObject, eventname, model) =>
                if GoogleService.Map.isGMarker(gObject) && gObject.markerType == "streetNum"
                  return
                model = GoogleService.UiMap.getCorrectModel model
                $timeout.cancel(@mouseoutDebounce)
                @mouseoutDebounce = $timeout () =>
                  _handleMouseout(model)
                , limits.options.throttle.eventPeriods.mouseout

              click: (gObject, eventname, model, events) =>
                $scope.$evalAsync =>
                  #delay click interaction to see if a dblclick came in
                  #if one did then we skip setting the click on resultFormatter to not show the details (cause our intention was to save)
                  event = events[0]
                  $timeout =>
                    #looks like google maps blocks ctrl down and click on gObjects (need to do super for windows (maybe meta?))
                    #also esc/escape works with Meta ie press esc and it locks meta down. press esc again meta is off
                    model = GoogleService.UiMap.getCorrectModel model
                    if event.ctrlKey or event.metaKey
                      return _saveProperty(model, gObject)
                    unless @lastEvent == 'dblclick'
                      $scope.formatters.results.click(@scope.layers.filterSummary[model.rm_property_id]||model, window.event, 'map')
                  , limits.clickDelayMilliSeconds

              dblclick: (gObject, eventname, model, events) =>
                @lastEvent = 'dblclick'
                event = events[0]
                if event.stopPropagation then event.stopPropagation() else (event.cancelBubble=true)
                model = GoogleService.UiMap.getCorrectModel model
                _saveProperty model, gObject
                $timeout =>
                  #cleanup
                  @lastEvent = undefined
                , limits.clickDelayMilliSeconds + 100

          formatters:
            layer: LayerFormatters(self)
            results: new ResultsFormatter(self)

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

        @scope.$watch 'zoom', (newVal, oldVal) =>
          #if there is a change close the listing view
          #it keeps the map running better on zooming as the infobox doesn't seem to scale well
          if @scope.layers.listingDetail?
            @scope.layers.listingDetail.show = false if newVal isnt oldVal
        #END SCOPE EXTENDING /////////////////////////////////////////////////////////////////////////////////////////
        @subscribe()
        uiGmapControls.init $scope.controls
        #END CONSTRUCTOR

      #BEGIN PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
      clearBurdenLayers: =>
        if @gMap? and not ZoomLevel.isAddressParcel(@gMap,@scope)
          @scope.layers.parcels.length = 0

      maybeShowGoogleParcelLines: =>
        if ZoomLevel.isParcel(@scope.zoom) or ZoomLevel.isAddressParcel(@scope.zoom)
          return if @didAddGParcelLinesStyle
          @didAddGParcelLinesStyle = true
          @scope.options.styles.push @scope.formatters.layer.Parcels.style
        else
          if @didAddGParcelLinesStyle
            @scope.options.styles = _.without(@scope.options.styles, @scope.formatters.layer.Parcels.style)
            @didAddGParcelLinesStyle = false

      redraw: (cache = true) =>
        #consider renaming parcels to addresses as that is all they are used for now
        @maybeShowGoogleParcelLines()
        if ZoomLevel.isAddressParcel(@scope.zoom, @scope)
          ZoomLevel.dblClickZoom.disable(@scope) if ZoomLevel.isAddressParcel(@scope.zoom)
          Properties.getParcelBase(@hash, @mapState, cache).then (data) =>
            return unless data?
            @scope.layers.parcels = uiGmapObjectIterators.slapAll data
            $log.debug "addresses count to draw: #{data.length}"
        else
          ZoomLevel.dblClickZoom.enable(@scope)
          @clearBurdenLayers()

        Properties.getFilterSummary(@hash, @mapState, @filters, cache).then (data) =>
          return unless data?
          @scope.layers.filterSummary = uiGmapObjectIterators.slapAll data
          $log.debug "filters (poly price) count to draw: #{data.length}"

          @scope.$evalAsync () =>
            @scope.formatters.results?.reset()


      draw: (event, paths) =>
        @scope.formatters.results?.reset()
        if not paths and not @scope.drawUtil.isEnabled
          paths = _.map @scope.bounds, (b) ->
            new google.maps.LatLng b.latitude, b.longitude

        if !paths? || paths.length < 2 || (paths.length == 2 && _.isEqual(paths...))
          return

        @hash = encode paths

        @refreshState()
        @redraw()

      getMapStateObj: =>
        centerToSave = undefined

        if @scope.center?.latitude? and @scope.center?.longitude?
          centerToSave = @scope.center
        else if @scope.center?.lat? and @scope.center?.lng?
          centerToSave =
            latitude: @scope.center.lat()
            longitude: @scope.center.lng()
        else
          #fallback to saftey and save a good center
          centerToSave = MainOptions.map.json.center

        stateObj =
          map_position:
            center: centerToSave
            zoom: @scope.zoom
          map_toggles: @scope.Toggles or {}

        if @scope.selectedResult? and @scope.selectedResult.rm_property_id?
          _.extend stateObj,
            map_results:
              selectedResultId: @scope.selectedResult.rm_property_id
        stateObj

      refreshState: (overrideObj = {}) =>
        @mapState = qs.stringify _.extend(@getMapStateObj(), overrideObj)
        @mapState

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

      clearFilter: =>
        @scope.layers.parcels.length = 0 #must clear so it is rebuilt!
        @scope.layers.filterSummary.length = 0
      #END PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
]
