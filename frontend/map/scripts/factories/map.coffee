###globals L,_,angular###
app = require '../app.coffee'
{NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')
Point = require('../../../../common/utils/util.geometries.coffee').Point

_encode = require('geohash64').encode
_emptyGeoJsonData =
  type: 'FeatureCollection'
  features: []

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
    rmapsMapEventsHandlerService,
    rmapsPopupLoaderService,
    rmapsPropertiesService,
    rmapsPropertyFormatterService,
    rmapsRenderingService,
    rmapsResultsFlow
    rmapsResultsFormatterService,
    rmapsMapTogglesFactory,
    rmapsZoomLevelService,
    rmapsZoomLevelStateFactory,
  ) ->

    leafletDataMainMap = new rmapsLeafletObjectFetcherFactory('mainMap')
    limits = rmapsMainOptions.map

    normal = $log.spawn("map:factory:normal")
    verboseLogger = $log.spawn("map:factory:verbose")
    $log = normal

    _initToggles = ($scope, toggles) ->
      return unless toggles?
      $scope.Toggles = toggles

    class Map extends rmapsBaseMapFactory

      @currentMainMap: null

      constructor: ($scope) ->
        @constructor.currentMainMap = @

        _.extend @, rmapsZoomLevelStateFactory(scope: $scope)
        _overlays = require '../utils/util.layers.overlay.coffee' #don't get overlays until your logged in
        super $scope, limits.options, limits.redrawDebounceMilliSeconds, 'map' ,'mainMap'

        _initToggles $scope, limits.toggles

        $scope.zoomLevelService = rmapsZoomLevelService
        self = @

        $rootScope.$onRootScope rmapsEventConstants.map.locationChange, (event, position) ->
          if position
            position = position.coords
          else
            position = $scope.previousCenter

          position.zoom = position.zoom ? rmapsZoomLevelService.getZoom($scope) ? 14
          $scope.map.center = NgLeafletCenter position
          $scope.$evalAsync()

        #
        # Property Button events
        #
        $rootScope.$onRootScope rmapsEventConstants.map.centerOnProperty, (event, result) =>
          @zoomTo result, false

        $rootScope.$onRootScope rmapsEventConstants.map.zoomToProperty, (event, result, doChangeZoom) =>
          @zoomTo result, doChangeZoom

        $rootScope.$onRootScope rmapsEventConstants.map.fitBoundsProperty, (event, bounds) =>
          @fitBounds bounds

        $rootScope.$onRootScope rmapsEventConstants.update.properties.pin, self.pinPropertyEventHandler

        $rootScope.$onRootScope rmapsEventConstants.update.properties.favorite, self.favoritePropertyEventHandler

        #
        # End Property Button Events
        #

        #
        # This promise is resolved when Leaflet has finished setting up the Map
        #
        leafletData.getMap('mainMap').then () =>

          $scope.$watch 'Toggles.showPrices', (newVal) ->
            $scope.map.layers.overlays?.filterSummary?.visible = newVal

          $scope.$watch 'Toggles.showAddresses', (newVal) ->
            if(_.get($scope, 'map.layers.overlays.parcelsAddresses')?)
              $scope.map.layers.overlays.parcelsAddresses.visible = newVal

          $scope.$watch 'Toggles.propertiesInShapes', (newVal, oldVal) =>
            $log.debug "Map Factory - Watch Toggles.propertiesInShapes: #{newVal} from #{oldVal}"
            $rootScope.propertiesInShapes = newVal
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
            if newVal != oldVal
              if _firstCenter
                _firstCenter = false
                return
              @scope.previousCenter = oldVal
              @scope.Toggles.hasPreviousLocation = true
            else
              @scope.Toggles.hasPreviousLocation = false

        @singleClickCtrForDouble = 0

        $rootScope.$onRootScope rmapsEventConstants.map.center, (evt, location) ->
          $scope.Toggles.setLocation location

        @layerFormatter = rmapsLayerFormattersService

        @scope.refreshState = (overrideObj = {}) =>
          @mapState = _.extend {}, @getMapStateObj(), overrideObj

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

            getMail: () ->
              $q.resolve() #place holder for rmapsMapMailCtrl so we can access it here in this parent directive

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
          changeZoom: (increment) =>
            @scope.zoomLevelService.setPrevZoom self.map.getZoom()
            toBeZoom = self.map.getZoom() + increment
            @scope.zoomLevelService.setCurrZoom toBeZoom
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

        unless filters?.status?
          @clearFilterSummary()
          return $q.resolve()

        rmapsPropertiesService.getFilterResults(@hash, @mapState, filters, cache)
        .then (data) =>
          rmapsResultsFlow {
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
        # $q.all(promises).then =>
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

      openWindow: (model) =>
        opts = {@map, model}
        if model.mailings?
          opts.popupType = 'mail'
        rmapsPopupLoaderService.load(opts)

      closeWindow: ->
        rmapsPopupLoaderService.close()

      centerOn: (result) =>
        @zoomTo(result, false)

      zoomTo: (result, doChangeZoom) ->
        verboseLogger.debug "CAUGHT zoomToProperty event"
        if result.geometry?
          result =  result.geometry

        if !result?.coordinates?.length > 1
          return

        resultCenter = new Point(result.coordinates[1],result.coordinates[0])
        old = _.cloneDeep @scope.map.center
        resultCenter.zoom = old.zoom
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
          wasSaved = result?.savedDetails?.isPinned

          # Handle the leaflet objects
          #update markers immediately
          lObject = leafletDataMainMap.get(result.rm_property_id, 'filterSummary')?.lObject
          rmapsLayerFormattersService.MLS.setMarkerPriceOptions(result, @scope)
          lObject?.setIcon(new L.divIcon(result.icon))
          #update polygons immediately
          lObject = leafletDataMainMap.get(result.rm_property_id, 'filterSummaryPoly')?.lObject
          lObject.setStyle(rmapsLayerFormattersService.Parcels.getStyle(result))

          #make sure selectedResult is updated if it exists
          summary = @scope.map?.markers?.filterSummary
          if @scope.selectedResult? and summary[@scope.selectedResult.rm_property_id]?
            delete @scope.selectedResult.savedDetails
            angular.extend(@scope.selectedResult, summary[@scope.selectedResult.rm_property_id])

          if wasSaved and !@scope.results[result.rm_property_id]
            result.isMousedOver = undefined

        @redraw(false)

      favoritePropertyEventHandler: (event, eventData) =>
        result = eventData.property

        if result
          wasFavorite = result?.savedDetails?.isFavorite
          if wasFavorite and !@scope.results[result.rm_property_id]
            result.isMousedOver = undefined

          lObject = leafletDataMainMap.get(result.rm_property_id, 'filterSummary')?.lObject
          rmapsLayerFormattersService.MLS.setMarkerPriceOptions(result, @scope)
          lObject?.setIcon(new L.divIcon(result.icon))

      #END PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
