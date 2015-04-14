app = require '../app.coffee'
qs = require 'qs'
backendRoutes = require '../../../common/config/routes.backend.coffee'
analyzeValue = require '../../../common/utils/util.analyzeValue.coffee'


_encode = require('geohash64').encode
_overlays = require '../utils/util.layers.overlay.coffee'
_eventReg = require '../utils/util.events.coffee'
_emptyGeoJsonData =
  type: "FeatureCollection"
  features: []


###
  Our Main Map Implementation
###
app.factory 'Map'.ourNs(), ['Logger'.ourNs(), '$timeout', '$q', '$rootScope', 'uiGmapGoogleMapApi',
  'BaseMap'.ourNs(), 'Properties'.ourNs(), 'events'.ourNs(), 'LayerFormatters'.ourNs(), 'MainOptions'.ourNs(),
  'ParcelEnums'.ourNs(), 'uiGmapGmapUtil', 'FilterManager'.ourNs(), 'ResultsFormatter'.ourNs(), 'ZoomLevel'.ourNs(),
  'GoogleService'.ourNs(), 'uiGmapControls'.ourNs(), 'uiGmapObjectIterators', 'popupLoader'.ourNs(),
  'leafletData',
  ($log, $timeout, $q, $rootScope, GoogleMapApi, BaseMap,
    Properties, Events, LayerFormatters, MainOptions,
    ParcelEnums, uiGmapUtil, FilterManager, ResultsFormatter, ZoomLevel, GoogleService,
    uiGmapControls, uiGmapObjectIterators, PopupLoader, leafletData) ->

    _initToggles = ($scope, toggles) ->
      _handleMoveToMyLocation = (position) ->
        unless position
          position =
            coords: $scope.previousCenter
        $scope.center = position.coords
        $scope.$evalAsync()

      toggles.setLocationCb(_handleMoveToMyLocation)
      $scope.Toggles = toggles

    class Map extends BaseMap
      baseIsLoaded = false
      scopeM: ->
        @scope.map
      constructor: ($scope, limits) ->
        $scope.isReady = ->
          $scope.map.center? and $scope.map.layers and baseIsLoaded

        super $scope, limits.options, limits.redrawDebounceMilliSeconds, 'map' ,'mainMap'
        baseIsLoaded = true
        _initToggles $scope, limits.toggles

        $scope.zoomLevelService = ZoomLevel
        self = @

        leafletData.getMap('mainMap').then (map) =>

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
            limits: limits

        @singleClickCtrForDouble = 0
        $log.debug $scope.map
        $log.debug "map center: #{JSON.stringify($scope.map.center)}"
        $log.debug "map zoom: #{JSON.stringify($scope.map.center.zoom)}"


        @mouseoutDebounce = null

        @filters = ''
        @filterDrawPromise = false
        $rootScope.$watch('selectedFilters', @filter, true)
        @scope.savedProperties = Properties.getSavedProperties()
        @layerFormatter = LayerFormatters(@)

        _updateGObjects = (gObject, savedDetails, model) =>
          #purpose to to take some sort of gObject and update its view immediately
          model.savedDetails = savedDetails
          if GoogleService.Map.isGMarker(gObject)
            @layerFormatter.MLS.setMarkerPriceOptions model
          else
            opts =  @layerFormatter.Parcels.optionsFromFill(model)
            @redraw()
          $scope.formatters.results?.reset()

        @updateAllLayersByModel = _updateAllLayersByModel = (model) =>
          uiGmapControls.eachSpecificGObject model.rm_property_id, (gObject) ->
            if GoogleService.Map.isGMarker(gObject)
              @layerFormatter.MLS.setMarkerPriceOptions(model)
            else
              opts = @layerFormatter.Parcels.optionsFromFill(model)
            @redraw()
          , ['streetNumMarkers']

        _isModelInFilterSummary = (model) ->
          model.index?

        @saveProperty = (model, lObject) =>
          #TODO: Need to debounce / throttle
          saved = Properties.saveProperty(model)
          return unless saved
          saved.then (savedDetails) =>
            @redraw(false)
            (model, lObject) =>
              #TODO: Need to debounce / throttle
              saved = Properties.saveProperty(model)
              return unless saved
              saved.then (savedDetails) =>
                @redraw(false)
        #BEGIN SCOPE EXTENDING /////////////////////////////////////////////////////////////////////////////////////////
        _eventReg($timeout,$scope, @, limits)
        _.merge @scope,
          streetViewPanorama:
            status: 'OK'
          control: {}

          listingOptions:
            boxClass: 'custom-info-window'
            closeBoxDiv: ' '

          map:
            layers:
              overlays: _overlays

            listingDetail: undefined

            markers:
              filterSummary:{}
              backendPriceCluster:{}
              addresses:{}

            geojson: {}

          controls:
            parcels: {}
            satParcels: {}
            streetNumMarkers: {}
            priceMarkers: {}
            streetView: {}

          drawUtil:
            draw: undefined
            isEnabled: false


          formatters:
            results: new ResultsFormatter(self)

          dragZoom: {}
          changeZoom: (increment) ->
            toBeZoom = self.map.getZoom() + increment
            self.map.setZoom(toBeZoom)

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
          if @scopeM().listingDetail?
            @scopeM().listingDetail.show = false if newVal isnt oldVal
        #END SCOPE EXTENDING ////////////////////////////////////////////////////////////
        @subscribe()
        uiGmapControls.init $scope.controls
        #END CONSTRUCTOR

      #BEGIN PUBLIC HANDLES /////////////////////////////////////////////////////////////
      clearBurdenLayers: =>
        if @map? and not ZoomLevel.isAddressParcel(@map,@scope)
          _.each @scopeM().geojson, (val) ->
            val.data = _emptyGeoJsonData

      drawFilterSummary:(cache) =>
        promises = []
        if ZoomLevel.doCluster(@scope)
          promises.push(
            Properties.getFilterSummaryAsCluster(@hash, @mapState, @filters, cache)
            .then (data) =>
              return if !data? or _.isString data
              #data should be in array format
              @scopeM().markers.filterSummary = {}
              _.each data, (model,k) =>
                @layerFormatter.MLS.setMarkerManualClusterOptions(model)
              @scopeM().markers.backendPriceCluster = data
          )
        else
          #needed for results list, rendering price markers, and address Markers
          #depending on zoome we want address or price
          #the data structure is the same (do we clone and hide one?)
          #or do we have the results list view grab one that exists with items?
          promises.push(
            Properties.getFilterSummary(@hash, @mapState, @filters, cache)
            .then (data) =>
              return if !data? or _.isString data
              @scopeM().markers.backendPriceCluster = {}

              @layerFormatter.setDataOptions(data, @layerFormatter.MLS.setMarkerPriceOptions)

              @scopeM().markers.filterSummary = data

              $log.debug "filters (poly price) count to draw: #{_.keys(data).length}"
          )

          if ZoomLevel.isAddressParcel(@scopeM().center.zoom)
            @scope.map.layers.overlays.filterSummary.visible = false
            @scope.map.layers.overlays.addresses.visible = true
            promises.push(
              Properties.getFilterSummaryAsGeoJsonPolys(@hash, @mapState, @filters, cache)
              .then (data) =>
                return if !data? or _.isString data
                @scopeM().geojson.filterSummary =
                  data: data
                  style: @layerFormatter.Parcels.getStyle
            )
          else
            @scope.map.layers.overlays.filterSummary.visible = true
            @scope.map.layers.overlays.addresses.visible = false
        promises

      redraw: (cache = true) =>
        promises = []
        #consider renaming parcels to addresses as that is all they are used for now
        if ZoomLevel.isAddressParcel(@scopeM().center.zoom, @scope) or
             ZoomLevel.isParcel(@scopeM().center.zoom)
          if ZoomLevel.isAddressParcel(@scopeM().center.zoom)
              ZoomLevel.dblClickZoom.disable(@scope)

              promises.push(Properties.getAddresses(@hash, @mapState, cache).then( (data) =>
                @scope.map.markers.addresses = @layerFormatter.setDataOptions(
                  _.cloneDeep(data),
                  @layerFormatter.Parcels.labelFromStreetNum
                )
              ))

          promises.push(Properties.getParcelBase(@hash, @mapState, cache).then( (data) =>
            return unless data?
            @scopeM().geojson.parcelBase =
              data: data
              style: @layerFormatter.Parcels.style

            $log.debug "addresses count to draw: #{data?.features?.length}"
          ))

        else
          ZoomLevel.dblClickZoom.enable(@scope)
          @clearBurdenLayers()

        promises = promises.concat @drawFilterSummary(cache)

        $q.all(promises).then =>
          #every thing is setup, only draw once
          @directiveControls.geojson.create(@scope.map.geojson)
          @directiveControls.markers.create(@scope.map.markers)
          @scope.$evalAsync =>
            @scope.formatters.results?.reset()


      draw: (event, paths) =>
        return if !@directiveControls? or !@scope.isReady()

        @scope.formatters.results?.reset()
        if not paths and not @scope.drawUtil.isEnabled
          paths  = []
          for k, b of @scope.map.bounds
            paths.push [b.lat, b.lng]

        if !paths? or paths.length < 2 or
          (@scope.map?.bounds.northEast.lat == @scope.map?.bounds.southWest.lat and @scope.map?.bounds.northEast.lon == @scope.map?.bounds.southWest.lon)
            return

        @hash = _encode paths

        @refreshState()
        @redraw()

      getMapStateObj: =>
        centerToSave = undefined

        if @scopeM().center?.latitude? and @scopeM().center?.longitude?
          centerToSave = @scopeM().center
        else if @scopeM().center?.lat? and @scopeM().center?.lng?
          centerToSave =
            latitude: @scopeM().center.lat()
            longitude: @scopeM().center.lng()
        else
          #fallback to saftey and save a good center
          centerToSave = MainOptions.json.center

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
        return if not newFilters and not oldFilters
        if @filterDrawPromise
          $timeout.cancel(@filterDrawPromise)

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

      openWindow: (model) =>
        PopupLoader.load(@scope, @map, model)

      closeWindow: ->
        PopupLoader.close()

      ###
              closeListing: ->

              if $scope.map.listingDetail
                $scope.map.listingDetail.show = false
              model.show = true
              $scope.map.listingDetail = model
              offset = @layerFormatter.MLS.getWindowOffset(@gMap, $scope.map.listingDetail)
              return unless offset
              _.extend $scope.listingOptions,
                pixelOffset: offset
                disableAutoPan: true
      ###
      #END PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
]
