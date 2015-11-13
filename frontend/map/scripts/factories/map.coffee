app = require '../app.coffee'
qs = require 'qs'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{Point, NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')

_encode = require('geohash64').encode
_emptyGeoJsonData =
  type: 'FeatureCollection'
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
  (nemSimpleLogger, $timeout, $q, $rootScope, $http, rmapsBaseMap,
  rmapsPropertiesService, rmapsevents, rmapsLayerFormatters, rmapsMainOptions,
  rmapsFilterManager, rmapsResultsFormatter, rmapsZoomLevel,
  rmapsPopupLoader, leafletData, rmapsControls, rmapsRendering, rmapsMapTestLogger, rmapsMapEventsHandlerService) ->

    limits = rmapsMainOptions.map

    $log = nemSimpleLogger.spawn("map:factory")
    testLogger = rmapsMapTestLogger

    _initToggles = ($scope, toggles) ->
      return unless toggles?
      _handleMoveToMyLocation = (position) ->
        if position
          position = position.coords
        else
          position = $scope.previousCenter

        position.zoom = rmapsZoomLevel.getZoom($scope) ? 14
        $scope.map.center = NgLeafletCenter position
        $scope.$evalAsync()

      if toggles?.setLocationCb?
        toggles.setLocationCb(_handleMoveToMyLocation)
      $scope.Toggles = toggles

    class Map extends rmapsBaseMap
      baseIsLoaded = false

      constructor: ($scope) ->
        _overlays = require '../utils/util.layers.overlay.coffee' #don't get overlays until your logged in
        super $scope, limits.options, limits.redrawDebounceMilliSeconds, 'map' ,'mainMap'

        _initToggles $scope, limits.toggles

        $scope.zoomLevelService = rmapsZoomLevel
        self = @

        leafletData.getMap('mainMap').then (map) =>

          $scope.$watch 'Toggles.showPrices', (newVal) ->
            if $scope.map.layers.overlays?.filterSummary?
              $scope.map.layers.overlays.filterSummary.visible = newVal

          $scope.$watch 'Toggles.showAddresses', (newVal) ->
            if $scope.map.layers.overlays?.parcelsAddresses?
              $scope.map.layers.overlays.parcelsAddresses.visible = newVal

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

        @singleClickCtrForDouble = 0

        $rootScope.$onRootScope rmapsevents.map.filters.updated, => #tried without the closure and bombs
          @redraw()

        @layerFormatter = rmapsLayerFormatters

        @saveProperty = (model, lObject) =>
          #TODO: Need to debounce / throttle
          saved = rmapsPropertiesService.saveProperty(model)
          rmapsLayerFormatters.MLS.setMarkerPriceOptions(model, @scope)
          lObject.setIcon(new L.divIcon(model.icon))
          return unless saved
          saved.then (savedDetails) =>
            @redraw(false)

        @favoriteProperty = (model, lObject) =>
          #TODO: Need to debounce / throttle
          saved = rmapsPropertiesService.favoriteProperty(model)
          rmapsLayerFormatters.MLS.setMarkerPriceOptions(model, @scope)
          lObject.setIcon(new L.divIcon(model.icon))
          return unless saved
          saved.then (savedDetails) =>
            @redraw(false)

        @scope.refreshState = (overrideObj = {}) =>
          @mapState = qs.stringify _.extend(@getMapStateObj(), overrideObj)
          @mapState

        #BEGIN SCOPE EXTENDING /////////////////////////////////////////////////////////////////////////////////////////
        @eventHandle = rmapsMapEventsHandlerService(@)
        _.merge @scope,
          streetViewPanorama:
            status: 'OK'
          control: {}

          listingOptions:
            boxClass: 'custom-info-window'
            closeBoxDiv: ' '

          map:
            getNotes: () ->
              $q.resolve() #place holder for rmapsMapNotesCtrl so we can access it here in this parent directive

            layers:
              overlays: _overlays($log)

            listingDetail: undefined

            markers:
              filterSummary:{}
              backendPriceCluster:{}
              addresses:{}
              notes: []

            geojson: {}

          #TODO: Redesign this
          controls:
            custom: [
              rmapsControls.NavigationControl scope: $scope #this is very hackish angular
              rmapsControls.PropertiesControl scope: $scope #this is very hackish angular
              rmapsControls.LayerControl scope: $scope
              self.zoomBox
              rmapsControls.LocationControl scope: $scope
            ]



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
        #END CONSTRUCTOR

      #BEGIN PUBLIC HANDLES /////////////////////////////////////////////////////////////
      clearBurdenLayers: =>
        if @map? and not rmapsZoomLevel.isParcel(@scope.map.center.zoom)
          @scope.map.markers.addresses = {}
          @scope.map.markers.notes = []
          _.each @scope.map.geojson, (val) ->
            val.data = _emptyGeoJsonData

      clearFilterSummary: =>
        @scope.map.geojson.filterSummaryPoly =
          data: _emptyGeoJsonData
          style: @layerFormatter.Parcels.getStyle

        @scope.map.markers.filterSummary = {}

      handleClusterResults: (data) =>
        @scope.map.markers.filterSummary = {}
        clusters = {}
        for k, model of data
          # Need to ensure unique keys for markers so old ones get removed, new ones get added. Dashes must be removed.
          clusters["#{model.count}:#{model.lat}:#{model.lng}".replace('-','N')] = @layerFormatter.MLS.setMarkerManualClusterOptions(model)
        @scope.map.markers.backendPriceCluster = clusters

      handleSummaryResults: (data) =>
        @scope.map.markers.backendPriceCluster = {}
        @layerFormatter.setDataOptions(data, @layerFormatter.MLS.setMarkerPriceOptions)

        for key, model of data
          _wrapGeomPointJson model
          rmapsPropertiesService.updateProperty model

        @scope.map.markers.filterSummary = data

      handleGeoJsonResults: (filters, cache) =>
        rmapsPropertiesService.getFilterSummaryAsGeoJsonPolys(@hash, @mapState, filters, cache)
        .then (data) =>
          return if !data? or _.isString data

          for key, model of data
            rmapsPropertiesService.updateProperty model

          @scope.map.geojson.filterSummaryPoly =
            data: data
            style: @layerFormatter.Parcels.getStyle

      drawFilterSummary:(cache) =>
        promises = []
        overlays = @scope.map.layers.overlays
        Toggles = @scope.Toggles

        # result-count-based clustering, backend will either give clusters or summary.  Get and test here.
        # no need to query backend if no status is designated (it would error out by default right now w/ no status constraint)
        filters = rmapsFilterManager.getFilters()
        # $log.debug filters
        if !/status/.test(filters)
          @clearFilterSummary()
          return promises

        # $log.debug "hash: #{@hash}"
        # $log.debug "mapState: #{@mapState}"
        #NOTE THE PROMISE of getFilterResults being coupled with the mutated (.then) is important otherwise the workflow gets messed up
        #mess up in that parcels are not always rendered when they should be
        p = rmapsPropertiesService.getFilterResults(@hash, @mapState, filters, cache).then (data) =>
          if Object.prototype.toString.call(data) is '[object Array]'
            return if !data? or _.isString data
            @handleClusterResults(data)

          else
            #needed for results list, rendering price markers, and address Markers
            #depending on zoome we want address or price
            #the data structure is the same (do we clone and hide one?)
            #or do we have the results list view grab one that exists with items?
            return if !data? or _.isString data
            @handleSummaryResults(data)

            if rmapsZoomLevel.isParcel(@scope.map.center.zoom) or rmapsZoomLevel.isAddressParcel(@scope.map.center.zoom)
              if overlays?.parcels?
                overlays.parcels.visible = ! !!rmapsZoomLevel.isBeyondCartoDb(@scope.map.center.zoom)

              Toggles.showAddresses = !!rmapsZoomLevel.isAddressParcel(@scope.map.center.zoom)

              Toggles.showPrices = false

              @handleGeoJsonResults(filters, cache)

            else
              overlays.parcels.visible = false if overlays?.parcels?
              Toggles.showPrices = true
              Toggles.showAddresses = false
        promises.push p
        promises

      redraw: (cache = true) =>
        promises = []
        #consider renaming parcels to addresses as that is all they are used for now
        if (rmapsZoomLevel.isAddressParcel(@scope.map.center.zoom, @scope) or
             rmapsZoomLevel.isParcel(@scope.map.center.zoom)) and rmapsZoomLevel.isBeyondCartoDb(@scope.map.center.zoom)
          testLogger.debug 'isAddressParcel'
          promises.push rmapsPropertiesService.getParcelBase(@hash, @mapState, cache).then (data) =>
            return unless data?
            @scope.map.geojson.parcelBase =
              data: data
              style: @layerFormatter.Parcels.style

            $log.debug "addresses count to draw: #{data?.features?.length}"

        else
          testLogger.debug 'not, isAddressParcel'
          rmapsZoomLevel.dblClickZoom.enable(@scope)
          @clearBurdenLayers()

        promises = promises.concat @drawFilterSummary(cache), [@scope.map.getNotes()]

        $q.all(promises).then =>
          #every thing is setup, only draw once
          ###
          Not only is this efficent but it avoids (worksaround) ng-leaflet race
          https://github.com/tombatossals/angular-leaflet-directive/issues/820
          ###
          if @directiveControls
            @directiveControls.geojson.create(@scope.map.geojson)
            @directiveControls.markers.create(@scope.map.markers)
          @scope.$evalAsync =>
            @scope.formatters.results?.reset()


      draw: (event, paths) =>
        testLogger.debug 'draw'
        return if !@scope.map.isReady
        testLogger.debug 'isReady'
        @scope?.formatters?.results?.reset()
        #not getting bounds from scope as this is the most up to date and skips timing issues
        lBounds = _.pick(@map.getBounds(), ['_southWest', '_northEast'])
        return if lBounds._northEast.lat == lBounds._southWest.lat and lBounds._northEast.lng == lBounds._southWest.lng
        testLogger.debug 'lBounds'
        if not paths #and not @scope.drawUtil.isEnabled
          paths  = []
          for k, b of lBounds
            if b?
              paths.push [b.lat, b.lng]

        if !paths? or paths.length < 2
          return
        testLogger.debug 'paths'
        @hash = _encode paths
        testLogger.debug 'encoded hash'
        @scope.refreshState()
        testLogger.debug 'refreshState'
        ret = @redraw()
        testLogger.debug 'redraw'
        ret

      getMapStateObj: =>
        centerToSave = undefined

        try
          # This guarantees all lat/lon properties are in sync
          centerToSave = NgLeafletCenter(
            lat: @scope.map.center.lat ? @scope.map.center.latitude,
            lng: @scope.map.center.lng ? @scope.map.center.lon ? @scope.map.center.longitude
            zoom: @scope.map.center.zoom
          )
        catch
          #fallback to saftey and save a good center
          centerToSave = rmapsMainOptions.json.center

        stateObj =
          map_position:
            center: centerToSave
            zoom: @scope.zoom
          map_toggles: @scope.Toggles or {}

        if @scope.selectedResult?.rm_property_id?
          _.extend stateObj,
            map_results:
              selectedResultId: @scope.selectedResult.rm_property_id
        stateObj

      openWindow: (model, lTriggerObject) =>
        rmapsPopupLoader.load(@scope, @map, model, lTriggerObject)

      closeWindow: ->
        rmapsPopupLoader.close()

      #END PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
