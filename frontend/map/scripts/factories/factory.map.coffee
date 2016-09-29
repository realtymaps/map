###globals L,_,angular###
app = require '../app.coffee'
{NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')
Point = require('../../../../common/utils/util.geometries.coffee').Point


_encode = require('geohash64').encode
_emptyGeoJsonData =
  type: 'FeatureCollection'
  features: []

app.service 'rmapsCurrentMapService', () ->
  # This service keeps track of active map instance and id reference.
  # A new id and instance are needed each time a new one is created since it takes time for
  #   a stale reference to $destroy while we're actively using the active instance

  _mainMapBase = 'mainMap'
  _mainMapIndex = 0
  _currentMainMap = null
  _getId = () ->
    return _mainMapBase + _mainMapIndex
  _incr = () ->
    _mainMapIndex += 1


  set: (map) ->
    _currentMainMap = map
  get: () ->
    _currentMainMap

  makeNewMapId: () ->
    _incr()
    return _getId()

  mainMapId: () ->
    return _getId()

###
  Our Main Map Implementation
###
app.factory 'rmapsMapFactory',
  (
    $http,
    $log,
    $q,
    $rootScope,
    $timeout,
    leafletData,
    rmapsBaseMapFactory,
    rmapsControlsService,
    rmapsEventConstants,
    rmapsFilterManagerService,
    rmapsLayerFormattersService,
    rmapsLeafletObjectFetcherFactory,
    rmapsMainOptions,
    rmapsEventsHandlerService,
    rmapsPropertiesService,
    rmapsPropertyFormatterService,
    rmapsRenderingService,
    rmapsLayerManager
    rmapsResultsFormatterService,
    rmapsMapTogglesFactory,
    rmapsZoomLevelService,
    rmapsZoomLevelStateFactory,
    rmapsOverlays
    rmapsLayerUtilService,
    rmapsCurrentMapService
  ) ->

    limits = rmapsMainOptions.map

    normal = $log.spawn("map:factory:normal")
    verboseLogger = $log.spawn("map:factory:verbose")
    $log = normal

    _initToggles = ($scope, toggles) ->
      return unless toggles?
      $scope.Toggles = toggles

    class Map extends rmapsBaseMapFactory

      constructor: ($scope) ->
        super {
          scope: $scope
          options: limits.options
          redrawDebounceMilliSeconds: limits.redrawDebounceMilliSeconds
          mapPath: 'map'
          # need a new mapId instance and reference since it takes time for a former mapId to $destroy,
          # and this ensures we're always referencing the correct map instance and reference
          mapId: rmapsCurrentMapService.makeNewMapId()
        }

        rmapsCurrentMapService.set(@)
        @undrawn = true # this flag helps ensure we don't get cached results the first time we `draw()`
        @leafletDataMainMap = new rmapsLeafletObjectFetcherFactory(@mapId)
        _.extend @, rmapsZoomLevelStateFactory(scope: $scope)

        rmapsOverlays.init()
        .then (overlays) ->
          #using merge to not clobber objects
          _.merge $scope.map, layers: {overlays}


        _initToggles $scope, limits.toggles

        $scope.zoomLevelService = rmapsZoomLevelService
        self = @

        #
        # Property Button events
        #

        @scope.$on '$destroy', () =>
          $log.debug "Map instance #{@mapId} has been $destroyed."

        locationHandler = $rootScope.$onRootScope rmapsEventConstants.map.locationChange, (event, position) =>
          @setLocation(position)
        @scope.$on '$destroy', locationHandler

        centerOnPropHandler = $rootScope.$onRootScope rmapsEventConstants.map.centerOnProperty, (event, result) =>
          @zoomTo result, false
        @scope.$on '$destroy', centerOnPropHandler

        zoomHandler = $rootScope.$onRootScope rmapsEventConstants.map.zoomToProperty, (event, result, doChangeZoom) =>
          @zoomTo result, doChangeZoom
        @scope.$on '$destroy', zoomHandler

        boundsHandler = $rootScope.$onRootScope rmapsEventConstants.map.fitBoundsProperty, (event, bounds, options) =>
          @fitBounds bounds, options
        @scope.$on '$destroy', boundsHandler

        pinsHandler = $rootScope.$onRootScope rmapsEventConstants.update.properties.pin, self.pinPropertyEventHandler
        @scope.$on '$destroy', pinsHandler

        favsHandler = $rootScope.$onRootScope rmapsEventConstants.update.properties.favorite, self.favoritePropertyEventHandler
        @scope.$on '$destroy', favsHandler

        centerHandler = $rootScope.$onRootScope rmapsEventConstants.map.center, (evt, location) =>
          @setLocation location
        @scope.$on '$destroy', centerHandler

        #
        # End Property Button Events
        #

        #
        # This promise is resolved when Leaflet has finished setting up the Map
        #
        leafletData.getMap(@mapId).then () =>

          $scope.$watch 'Toggles.showPrices', (newVal) ->
            $scope.map.layers.overlays?.filterSummary?.visible = newVal

          $scope.$watch 'Toggles.showMail', (newVal) ->
            $log.debug 'Toggles.showMail', $scope.map.layers.overlays?.mail?.visible, newVal
            $scope.map.layers.overlays?.mail?.visible = newVal

          $scope.$watch 'Toggles.showAddresses', (newVal) ->
            $scope.map.layers.overlays?.parcelsAddresses?.visible = newVal

          $scope.$watch 'Toggles.propertiesInShapes', (newVal, oldVal) =>
            $log.debug "Map Factory - Watch Toggles.propertiesInShapes: #{newVal} from #{oldVal}"
            $rootScope.propertiesInShapes = newVal
            @redraw()

          $scope.$watch 'map.layers.overlays', (newVal) =>
            $scope.map.layers.overlays?.filterSummary?.visible = !!$scope.Toggles.showPrices
            $scope.map.layers.overlays?.mail?.visible = !!$scope.Toggles.showMail
            if !!$rootScope.propertiesInShapes != !!$scope.Toggles.propertiesInShapes
              $rootScope.propertiesInShapes = !!$scope.Toggles.propertiesInShapes
              @redraw()

          [
            rmapsEventConstants.map.filters.updated
            rmapsEventConstants.map.mainMap.redraw
          ].forEach (eventName) =>
            $scope.$on eventName, (event, cache) =>
              if !_.isBoolean cache
                cache = false
              @redraw(cache)


          _firstCenter = true
          @scope.$watchCollection 'map.center', (newVal, oldVal) =>
            if newVal == oldVal
              @scope.Toggles.hasPreviousLocation = false
              return

            if _firstCenter
              _firstCenter = false
              return

            @scope.previousCenter = oldVal
            @scope.Toggles.hasPreviousLocation = true


        @singleClickCtrForDouble = 0

        @layerFormatter = rmapsLayerFormattersService

        @scope.refreshState = (overrideObj = {}) =>
          @mapState = _.extend {}, @getMapStateObj(), overrideObj

        #BEGIN SCOPE EXTENDING /////////////////////////////////////////////////////////////////////////////////////////
        @eventHandle = rmapsEventsHandlerService(@)

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

            getMail: () ->
              $q.resolve() #place holder for rmapsMapMailCtrl so we can access it here in this parent directive

            listingDetail: undefined

            markers:
              filterSummary:{}
              backendPriceCluster:{}
              addresses:{}
              notes: {}
              currentLocation: {}

            geojson: {}

          #TODO: Redesign this
          controls:
            custom: [
              rmapsControlsService.NavigationControl scope: $scope #this is very hackish angular
              rmapsControlsService.PropertiesControl scope: $scope #this is very hackish angular
              rmapsControlsService.LayerControl scope: $scope
              self.zoomBox
              rmapsControlsService.LocationControl scope: $scope
            ]

          formatters:
            results: new rmapsResultsFormatterService(self)
            property: new rmapsPropertyFormatterService()

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
      updateToggles: (map_toggles) =>
        @scope.Toggles = rmapsMainOptions.map.toggles = new rmapsMapTogglesFactory(map_toggles)

      clearBurdenLayers: () =>
        d = $q.defer()
        @scope.$evalAsync =>
          if @map? and not rmapsZoomLevelService.isParcel(@scope.map.center.zoom)
            @scope.map.markers.addresses = {}
            @scope.map.markers.notes = []
            _.each @scope.map.geojson, (val) ->
              val.data = _emptyGeoJsonData
          d.resolve()
        d.promise

      clearFilterSummary: =>
        @scope.map.geojson.filterSummaryPoly =
          data: _emptyGeoJsonData
          style: @layerFormatter.Parcels.getStyle

        @scope.map.markers.filterSummary = {}

      drawFilterSummary: (cache) ->
        # result-count-based clustering, backend will either give clusters or summary.  Get and test here.
        # no need to query backend if no status is designated (it would error out by default right now w/ no status constraint)
        filters = rmapsFilterManagerService.getFilters()

        if !filters?.status?
          @clearFilterSummary()
          return $q.resolve()

        rmapsPropertiesService.getFilterResults(@hash, @mapState, filters, cache)
        .then (data) =>
          # `@scope.$watch 'map.center.zoom',` would've been recommended method of tracking changing zoom values,
          # but gets buggy when rapidly changing zooms occurs.
          @scope.zoomLevelService.trackZoom(@scope)

          rmapsLayerManager {
            @scope
            filters
            @hash
            @mapState
            data
            cache
          }


      redraw: (cache = true) ->
        promise = null
        #consider renaming parcels to addresses as that is all they are used for now
        if @showClientSideParcels()
          verboseLogger.debug 'isAddressParcel'
          promise = rmapsPropertiesService.getParcelBase(@hash, @mapState, cache)
          .then (data) =>
            return unless data?
            #_parcelBase is a naming hack to have parcelBase render before individual filterPolys (allows them to be on top)
            @scope.map.geojson._parcelBase =
              data: data
              style: @layerFormatter.Parcels.style

            $log.debug "addresses count to draw: #{data?.features?.length}"

        else
          verboseLogger.debug 'not, isAddressParcel'
          rmapsZoomLevelService.dblClickZoom.enable(@scope)
          promise = @clearBurdenLayers()

        $q.all [promise, @drawFilterSummary(cache), @scope.map.getNotes(), @scope.map.getMail()]
        .then () =>
          # handle ui-leaflet / leaflet polygon stacked no click bug
          # https://realtymaps.atlassian.net/browse/MAPD-1295
          rmapsLayerUtilService.filterParcelsFromSummary {
            parcels: @scope.map?.geojson?._parcelBase?.data
            props: @scope.map?.geojson?.filterSummaryPoly?.data
          }

          #every thing is setup, only draw once
          ###
          Not only is this efficent but it avoids (worksaround) ng-leaflet race
          https://github.com/tombatossals/angular-leaflet-directive/issues/820
          ###
          $rootScope.$emit rmapsEventConstants.map.results, @scope.map
          if @directiveControls
            @directiveControls.geojson.create(@scope.map.geojson)
            @directiveControls.markers.create(@scope.map.markers)
          @scope.$evalAsync =>
            $log.debug 'map.coffee - redraw calling results reset()'
            @scope.formatters.results?.reset()


      draw: (event, paths) =>
        verboseLogger.debug 'draw'
        return if !@scope.map.isReady
        verboseLogger.debug 'isReady'

        $log.debug 'map.coffee - redraw calling results reset()'
        @scope?.formatters?.results?.reset()

        #not getting bounds from scope as this is the most up to date and skips timing issues
        lBounds = _.pick(@map.getBounds(), ['_southWest', '_northEast'])
        return if lBounds._northEast.lat == lBounds._southWest.lat and lBounds._northEast.lng == lBounds._southWest.lng
        verboseLogger.debug 'lBounds'
        if not paths #and not @scope.drawUtil.isEnabled
          paths  = []
          for k, b of lBounds
            if b?
              paths.push [b.lat, b.lng]

        if !paths? or paths.length < 2
          return
        verboseLogger.debug 'paths'
        @hash = _encode paths
        verboseLogger.debug 'encoded hash'
        @scope.refreshState()
        verboseLogger.debug 'refreshState'

        if @undrawn # flip flag and redraw with no cache if this map instance is "undrawn" (draw hasn't been called yet)
          @undrawn = false
          ret = @redraw(false)
        else
          ret = @redraw()
        verboseLogger.debug 'redraw'
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

      centerOn: (result) =>
        @zoomTo(result, false)

      zoomTo: (result, doChangeZoom) ->
        verboseLogger.debug "CAUGHT zoomToProperty event"
        geometry = result.geometry_center
        if geometry?
          result = geometry

        if !result?.coordinates?.length > 1
          return

        resultCenter = new Point(result.coordinates[1],result.coordinates[0])
        old = _.cloneDeep @scope.map.center
        resultCenter.zoom = old.zoom
        resultCenter.docWhere = 'rmapsMapFactory.zoomTo'
        @scope.map.center = resultCenter

        if !doChangeZoom
          return

        zoomLevel = @scope.options.zoomThresh.addressParcel
        zoomLevel = @scope.map.center.zoom if @scope.map.center.zoom > @scope.options.zoomThresh.addressParcel
        @scope.map.center.zoom = zoomLevel

        resultCenter.zoom = 20 if @scope.satMap?

      pinPropertyEventHandler: (event, eventData) =>
        result = eventData.property
        if result
          wasPinned = result?.savedDetails?.isPinned

          # Handle the leaflet objects
          #update markers immediately
          lObject = @leafletDataMainMap.get(result.rm_property_id, 'filterSummary')?.lObject
          rmapsLayerFormattersService.MLS.setMarkerPriceOptions(result, @scope)
          lObject?.setIcon(new L.divIcon(result.icon))
          #update polygons immediately
          lObject = @leafletDataMainMap.get(result.rm_property_id, 'filterSummaryPoly')?.lObject

          lObject?.setStyle(rmapsLayerFormattersService.Parcels.getStyle(result))

          #make sure selectedResult is updated if it exists
          summary = @scope.map?.markers?.filterSummary
          if @scope.selectedResult? and summary[@scope.selectedResult.rm_property_id]?
            delete @scope.selectedResult.savedDetails
            angular.extend(@scope.selectedResult, summary[@scope.selectedResult.rm_property_id])

          if wasPinned and !@scope.results[result.rm_property_id]
            result.isMousedOver = undefined
        @redraw(false)

      favoritePropertyEventHandler: (event, eventData) =>
        result = eventData.property
        if result
          wasFavorite = result?.savedDetails?.isFavorite
          if wasFavorite and !@scope.results[result.rm_property_id]
            result.isMousedOver = undefined

          lObject = @leafletDataMainMap.get(result.rm_property_id, 'filterSummary')?.lObject
          rmapsLayerFormattersService.MLS.setMarkerPriceOptions(result, @scope)
          lObject?.setIcon(new L.divIcon(result.icon))

      setLocation: (position) =>
        {isMyLocation} = position

        getZoom = () =>
          position.zoom = position.zoom ? rmapsZoomLevelService.getZoom(@scope) ? 14

        if position
          position = position.coords
          getZoom()
          positionCenter = NgLeafletCenter position

          if @scope.map.center.isEqual(positionCenter)
            return
        else
          position = @scope.previousCenter

        if isMyLocation
          @scope.map.markers.currentLocation.myLocation = rmapsLayerFormattersService.setCurrentLocationMarkerOptions(position)
          @redraw()

        getZoom()

        positionCenter.docWhere = 'rmapsMapFactory.zoomTo'
        @scope.map.center = positionCenter
        @scope.$evalAsync()

      #END PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
