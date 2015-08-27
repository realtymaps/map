app = require '../app.coffee'
qs = require 'qs'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_overlays = require '../utils/util.layers.overlay.coffee'
{Point, NgLeafletCenter} = require '../../../../common/utils/util.geometries.coffee'

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
    rmapsFilterManager, rmapsResultsFormatter, rmapsZoomLevel, rmapsPopupLoader, leafletData, rmapsControls) ->

    _initToggles = ($scope, toggles) ->
      _handleMoveToMyLocation = (position) ->
        if position
          position = position.coords
        else
          position = $scope.previousCenter

        position.zoom = rmapsZoomLevel.getZoom($scope) ? 14
        $scope.map.center = NgLeafletCenter position
        $scope.$evalAsync()

      toggles.setLocationCb(_handleMoveToMyLocation)
      $scope.Toggles = toggles

    class Map extends rmapsBaseMap
      baseIsLoaded = false

      constructor: ($scope, limits) ->

        super $scope, limits.options, limits.redrawDebounceMilliSeconds, 'map' ,'mainMap'
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
        $rootScope.$watchCollection 'selectedFilters', @filter#, true
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
            custom: [
              rmapsControls.NavigationControl scope: @scope
              rmapsControls.PropertiesControl scope: @scope
              rmapsControls.LayerControl scope: @scope
              @zoomBox
              rmapsControls.LocationControl scope: @scope
            ]

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
          if @scope.map.listingDetail?
            @scope.map.listingDetail.show = false if newVal isnt oldVal
        #END SCOPE EXTENDING ////////////////////////////////////////////////////////////
        @subscribe()
        #END CONSTRUCTOR

      #BEGIN PUBLIC HANDLES /////////////////////////////////////////////////////////////
      clearBurdenLayers: =>
        if @map? and not rmapsZoomLevel.isParcel(@scope.map.center.zoom)
          @scope.map.markers.addresses = {}
          _.each @scope.map.geojson, (val) ->
            val.data = _emptyGeoJsonData

      drawFilterSummary:(cache) =>
        self = @
        promises = []

        handleClusterResults = (data) ->
          self.scope.map.markers.filterSummary = {}
          _.each data, (model,k) ->
            self.layerFormatter.MLS.setMarkerManualClusterOptions(model)
          self.scope.map.markers.backendPriceCluster = data

        handleSummaryResults = (data) ->
          self.scope.map.markers.backendPriceCluster = {}
          self.layerFormatter.setDataOptions(data, self.layerFormatter.MLS.setMarkerPriceOptions)
          for key, val of data
            _wrapGeomPointJson val
          self.scope.map.markers.filterSummary = data

        handleGeoJsonResults = () ->
          rmapsProperties.getFilterSummaryAsGeoJsonPolys(self.hash, self.mapState, self.filters, cache)
          .then (data) ->
            return if !data? or _.isString data
            self.scope.map.geojson.filterSummaryPoly =
              data: data
              style: self.layerFormatter.Parcels.getStyle

        # result-count-based clustering, backend will either give clusters or summary.  Get and test here.
        if /status/.test(@filters) # no need to query backend if no status is designated (it would error out by default right now w/ no status constraint)
          promises.push(
            rmapsProperties.getFilterResults(@hash, @mapState, @filters, cache)
            .then (data) ->
              if Object.prototype.toString.call(data) is '[object Array]'
                return if !data? or _.isString data
                handleClusterResults(data)

              else
                #needed for results list, rendering price markers, and address Markers
                #depending on zoome we want address or price
                #the data structure is the same (do we clone and hide one?)
                #or do we have the results list view grab one that exists with items?
                return if !data? or _.isString data
                handleSummaryResults(data)

                if rmapsZoomLevel.isParcel(self.scope.map.center.zoom) or rmapsZoomLevel.isAddressParcel(self.scope.map.center.zoom)
                  self.scope.map.layers.overlays.parcels.visible = if rmapsZoomLevel.isBeyondCartoDb(self.scope.map.center.zoom) then false else true
                  self.scope.map.layers.overlays.filterSummary.visible = false
                  self.scope.map.layers.overlays.parcelsAddresses.visible = if rmapsZoomLevel.isAddressParcel(self.scope.map.center.zoom) then true else false

                  rmapsProperties.getFilterSummaryAsGeoJsonPolys(self.hash, self.mapState, self.filters, cache)
                  .then (data) ->
                    return if !data? or _.isString data
                    self.scope.map.geojson.filterSummaryPoly =
                      data: data
                      style: self.layerFormatter.Parcels.getStyle

                else
                  self.scope.map.layers.overlays.parcels.visible = false
                  self.scope.map.layers.overlays.filterSummary.visible = true
                  self.scope.map.layers.overlays.parcelsAddresses.visible = false
          )
        promises

      redraw: (cache = true) =>
        promises = []
        #consider renaming parcels to addresses as that is all they are used for now
        if (rmapsZoomLevel.isAddressParcel(@scope.map.center.zoom, @scope) or
             rmapsZoomLevel.isParcel(@scope.map.center.zoom)) and rmapsZoomLevel.isBeyondCartoDb(@scope.map.center.zoom)

          promises.push rmapsProperties.getParcelBase(@hash, @mapState, cache).then (data) =>
            return unless data?
            @scope.map.geojson.parcelBase =
              data: data
              style: @layerFormatter.Parcels.style

            $log.debug "addresses count to draw: #{data?.features?.length}"

        else
          rmapsZoomLevel.dblClickZoom.enable(@scope)
          @clearBurdenLayers()

        promises = promises.concat @drawFilterSummary(cache)

        $q.all(promises).then =>
          #every thing is setup, only draw once
          if @directiveControls
            @directiveControls.geojson.create(@scope.map.geojson)
            @directiveControls.markers.create(@scope.map.markers)
          @scope.$evalAsync =>
            @scope.formatters.results?.reset()


      draw: (event, paths) =>
        return if !@scope.map.isReady
        @scope?.formatters?.results?.reset()
        #not getting bounds from scope as this is the most up to date and skips timing issues
        lBounds = _.pick(@map.getBounds(), ['_southWest', '_northEast'])
        return if lBounds._northEast.lat == lBounds._southWest.lat and lBounds._northEast.lon == lBounds._southWest.lon

        if not paths and not @scope.drawUtil.isEnabled
          paths  = []
          for k, b of lBounds
            if b?
              paths.push [b.lat, b.lng]

        if !paths? or paths.length < 2
          return

        @hash = _encode paths

        @refreshState()
        @redraw()

      getMapStateObj: =>
        centerToSave = undefined

        if @scope.map.center?.latitude? and @scope.map.center?.longitude?
          centerToSave = @scope.map.center
        else if @scope.map.center?.lat? and @scope.map.center?.lng?
          centerToSave =
            latitude: @scope.map.center.lat()
            longitude: @scope.map.center.lng()
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
        return if (not newFilters and not oldFilters) or newFilters == oldFilters
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
