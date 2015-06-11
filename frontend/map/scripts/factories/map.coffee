app = require '../app.coffee'
qs = require 'qs'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
analyzeValue = require '../../../../common/utils/util.analyzeValue.coffee'
_overlays = require '../utils/util.layers.overlay.coffee'

_encode = require('geohash64').encode

_eventReg = require '../utils/util.events.coffee'
_emptyGeoJsonData =
  type: "FeatureCollection"
  features: []

_wrapGeomPointJson = (obj) ->
  unless obj?.geom_point_json
    obj.geom_point_json =
      coordinates: obj.coordinates
      type: obj.type
  obj

###
  Our Main Map Implementation
###
app.factory 'rmapsMap',
  ($log, $timeout, $q, $rootScope, $http, rmapsBaseMap,
    rmapsProperties, rmapsevents, rmapsLayerFormatters, rmapsMainOptions,
    rmapsFilterManager, rmapsResultsFormatter, rmapsZoomLevel, rmapsPopupLoader, leafletData) ->


    _initToggles = ($scope, toggles) ->
      _handleMoveToMyLocation = (position) ->
        unless position
          position = $scope.previousCenter
        $scope.map.center = position
        $scope.$evalAsync()

      toggles.setLocationCb(_handleMoveToMyLocation)
      $scope.Toggles = toggles

    class Map extends rmapsBaseMap
      baseIsLoaded = false
      scopeM: ->
        @scope.map
      constructor: ($scope, limits) ->
        $scope.isReady = ->
          $scope.map.center? and $scope.map.layers and baseIsLoaded

        super $scope, limits.options, limits.redrawDebounceMilliSeconds, 'map' ,'mainMap'
        baseIsLoaded = true
        _initToggles $scope, limits.toggles

        $scope.zoomLevelService = rmapsZoomLevel
        self = @

        leafletData.getMap('mainMap').then (map) =>

          _firstCenter = true
          @scope.$watchCollection 'map.center', (newVal, oldVal) =>
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


        @filters = ''
        @filterDrawPromise = false
        $rootScope.$watch('selectedFilters', @filter, true)
        @scope.savedrmapsProperties = rmapsProperties.getSavedProperties()
        @layerFormatter = rmapsLayerFormatters(@)

        @saveProperty = (model, lObject) =>
          #TODO: Need to debounce / throttle
          saved = rmapsProperties.saveProperty(model)
          return unless saved
          saved.then (savedDetails) =>
            @redraw(false)
            (model, lObject) =>
              #TODO: Need to debounce / throttle
              saved = rmapsProperties.saveProperty(model)
              return unless saved
              saved.then (savedDetails) =>
                @redraw(false)
        #BEGIN SCOPE EXTENDING /////////////////////////////////////////////////////////////////////////////////////////
        @eventHandle = _eventReg($timeout,$scope, @, limits, $log)
        _.merge @scope,
          streetViewPanorama:
            status: 'OK'
          control: {}

          listingOptions:
            boxClass: 'custom-info-window'
            closeBoxDiv: ' '

          map:
            layers:
              overlays: _overlays($log)

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
            results: new rmapsResultsFormatter(self)

          dragZoom: {}
          changeZoom: (increment) ->
            toBeZoom = self.map.getZoom() + increment
            self.map.setZoom(toBeZoom)

        @scope.$watch 'zoom', (newVal, oldVal) =>
          #if there is a change close the listing view
          #it keeps the map running better on zooming as the infobox doesn't seem to scale well
          if @scopeM().listingDetail?
            @scopeM().listingDetail.show = false if newVal isnt oldVal
        #END SCOPE EXTENDING ////////////////////////////////////////////////////////////
        @subscribe()
        #END CONSTRUCTOR

      #BEGIN PUBLIC HANDLES /////////////////////////////////////////////////////////////
      clearBurdenLayers: =>
        if @map? and not rmapsZoomLevel.isParcel(@scopeM().center.zoom)
          @scopeM().markers.addresses = {}
          _.each @scopeM().geojson, (val) ->
            val.data = _emptyGeoJsonData

      drawFilterSummary:(cache) =>
        promises = []
        if rmapsZoomLevel.doCluster(@scope)
          promises.push(
            rmapsProperties.getFilterSummaryAsCluster(@hash, @mapState, @filters, cache)
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
            rmapsProperties.getFilterSummary(@hash, @mapState, @filters, cache)
            .then (data) =>
              return if !data? or _.isString data
              @scopeM().markers.backendPriceCluster = {}

              @layerFormatter.setDataOptions(data, @layerFormatter.MLS.setMarkerPriceOptions)

              for key, val of data
                _wrapGeomPointJson val

              @scopeM().markers.filterSummary = data

              $log.debug "filters (poly price) count to draw: #{_.keys(data).length}"
          )

          if rmapsZoomLevel.isParcel(@scopeM().center.zoom) or rmapsZoomLevel.isAddressParcel(@scopeM().center.zoom)
            @scope.map.layers.overlays.parcels.visible = if rmapsZoomLevel.isBeyondCartoDb(@scopeM().center.zoom) then false else true
            @scope.map.layers.overlays.filterSummary.visible = false
            @scope.map.layers.overlays.parcelsAddresses.visible = if rmapsZoomLevel.isAddressParcel(@scopeM().center.zoom) then true else false
            promises.push(
              rmapsProperties.getFilterSummaryAsGeoJsonPolys(@hash, @mapState, @filters, cache)
              .then (data) =>
                return if !data? or _.isString data
                @scopeM().geojson.filterSummaryPoly =
                  data: data
                  style: @layerFormatter.Parcels.getStyle
            )
          else
            @scope.map.layers.overlays.parcels.visible = false
            @scope.map.layers.overlays.filterSummary.visible = true
            @scope.map.layers.overlays.parcelsAddresses.visible = false
        promises

      redraw: (cache = true) =>
        promises = []
        #consider renaming parcels to addresses as that is all they are used for now
        if (rmapsZoomLevel.isAddressParcel(@scopeM().center.zoom, @scope) or
             rmapsZoomLevel.isParcel(@scopeM().center.zoom)) and rmapsZoomLevel.isBeyondCartoDb(@scopeM().center.zoom)

          promises.push rmapsProperties.getParcelBase(@hash, @mapState, cache).then (data) =>
            return unless data?
            @scopeM().geojson.parcelBase =
              data: data
              style: @layerFormatter.Parcels.style

            $log.debug "addresses count to draw: #{data?.features?.length}"

        else
          rmapsZoomLevel.dblClickZoom.enable(@scope)
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

        @scope?.formatters?.results?.reset()
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
          centerToSave = rmapsMainOptions.json.center

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
          rmapsFilterManager.manage (@filters) =>
            @filterDrawPromise = false
            @redraw()
        , rmapsMainOptions.filterDrawDelay

      subscribe: ->
        #subscribing to events (Angular's built in channel bubbling)
        @scope.$onRootScope rmapsevents.map.drawPolys.clear, =>
          _.each @scope.layers, (layer, k) ->
            return layer.length = 0 if layer? and _.isArray layer
            layer = {} #this is when a layer is an object

        @scope.$onRootScope rmapsevents.map.drawPolys.isEnabled, (event, isEnabled) =>
          @scope.drawUtil.isEnabled = isEnabled
          if isEnabled
            @scope.drawUtil.draw()

        @scope.$onRootScope rmapsevents.map.drawPolys.query, =>
          polygons = @scope.layers.drawnPolys
          paths = _.flatten polygons.map (polygon) ->
            _.reduce(polygon.getPaths().getArray()).getArray()
          @draw 'draw_tool', paths

      openWindow: (model) =>
        rmapsPopupLoader.load(@scope, @map, model)

      closeWindow: ->
        rmapsPopupLoader.close()

      #END PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
