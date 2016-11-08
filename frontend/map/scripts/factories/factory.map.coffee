###globals angular###
_ = require 'lodash'
L = require 'leaflet'
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
    rmapsCurrentMapService,
    rmapsFiltersFactory,
    rmapsProfilesService
  ) ->

    limits = rmapsMainOptions.map

    normal = $log.spawn("map:factory:normal")
    verboseLogger = $log.spawn("map:factory:verbose")
    $log = normal

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


        $scope.updateToggles(limits.toggles)

        $scope.zoomLevelService = rmapsZoomLevelService
        self = @

        #
        # Property Button events
        #

        locationHandler = $rootScope.$onRootScope rmapsEventConstants.map.locationChange, (event, position) =>
          @setLocation(position)

        zoomHandler = $rootScope.$onRootScope rmapsEventConstants.map.zoomToProperty, (event, result, doChangeZoom) =>
          @zoomTo result, doChangeZoom

        boundsHandler = $rootScope.$onRootScope rmapsEventConstants.map.fitBoundsProperty, (event, bounds, options) =>
          @fitBounds bounds, options

        pinsHandler = $rootScope.$onRootScope rmapsEventConstants.update.properties.pin, self.pinPropertyEventHandler

        favsHandler = $rootScope.$onRootScope rmapsEventConstants.update.properties.favorite, self.favoritePropertyEventHandler

        centerHandler = $rootScope.$onRootScope rmapsEventConstants.map.center, (evt, location) =>
          @setLocation location

        @scope.$on '$destroy', () =>
          locationHandler()
          zoomHandler()
          boundsHandler()
          pinsHandler()
          favsHandler()
          centerHandler()
          $log.debug "Map instance #{@mapId} has been $destroyed."


        #
        # End Property Button Events
        #

        #
        # This promise is resolved when Leaflet has finished setting up the Map
        #
        leafletData.getMap(@mapId).then (leafletMap) =>

          # here, getLayers returns empty array, so had to re-get them inside watch below...
          $scope.$watch 'Toggles.useSatellite', (newVal, oldVal) =>
            leafletData.getLayers(@mapId).then (allLayers) ->
              sat = allLayers.baselayers.mapbox_street_gybrid
              map = allLayers.baselayers.mapbox_street

              if sat? && map?
                layersForToggle =
                  true: sat
                  false: map

                leafletMap.removeLayer(layersForToggle[!newVal])
                leafletMap.addLayer(layersForToggle[newVal])
                if $scope.map.layers?.overlays?.parcels?.visible
                  # bring parcels to front if exists since the tiles render over them
                  allLayers.overlays.parcels.bringToFront()


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
              $log.debug "redrawing, got", eventName
              @redraw({cache})


          _firstCenter = true
          @scope.$watchCollection 'map.center', (newVal, oldVal) =>

            if newVal == oldVal
              @scope.Toggles.hasPreviousLocation = false
              return

            # keep our local profile up-to-date with position
            rmapsProfilesService.currentProfile.map_position.center = newVal

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
            property: rmapsPropertyFormatterService

          dragZoom: {}
          changeZoom: (increment) ->
            toBeZoom = self.map.getZoom() + increment
            self.map.setZoom(toBeZoom)

        @scope.$watch 'zoom', (newVal, oldVal) =>
          #if there is a change close the listing view
          #it keeps the map running better on zooming as the infobox doesn't seem to scale well
          if @scope.map.listingDetail?
            @scope.map.listingDetail.show = false if newVal isnt oldVal

        @scope.resetLayers = () =>
          @scope.updateToggles(showAddresses: false, showPrices: false)
          _.extend @scope.selectedFilters, rmapsFiltersFactory.valueDefaults,
            forSale: false
            pending: false
            sold: false

        #END SCOPE EXTENDING ////////////////////////////////////////////////////////////
        #END CONSTRUCTOR

      #BEGIN PUBLIC HANDLES /////////////////////////////////////////////////////////////

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

      drawFilterSummary: ({cache, event}) ->
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
            event
          }


      redraw: ({cache = true, event} = {}) ->
        verboseLogger.debug 'redraw() cache=', cache
        promise = null
        centerParcel = null
        #consider renaming parcels to addresses as that is all they are used for now
        if @showClientSideParcels()
          verboseLogger.debug 'isAddressParcel'
          promise = rmapsPropertiesService.getParcelBase(@hash, @mapState, cache)
          .then (data) =>
            return unless data?

            # note: multiple calls to redraw may occur, the correct one happens to have cache = true
            #   this feels like a hack to me, how can it be avoided?
            if cache
              for parcel in data.features
                if parcel.map_center && @showCenter
                  $log.debug "center set!!!", parcel.rm_property_id
                  centerParcel = parcel
                  parcel.isHighlighted = true

            #_parcelBase is a naming hack to have parcelBase render before individual filterPolys (allows them to be on top)
            @scope.map.geojson._parcelBase =
              data: data
              style: @layerFormatter.Parcels.style
              # onEachFeature: (feature, layer) ->
              #   layer.bindPopup(feature.rm_property_id)

            $log.debug "addresses count to draw: #{data?.features?.length}"

        else
          verboseLogger.debug 'not, isAddressParcel'
          rmapsZoomLevelService.dblClickZoom.enable(@scope)
          promise = @clearBurdenLayers()

        rmapsLayerUtilService.parcelTileVisSwitching({scope:@scope, event})

        $q.all [promise, @drawFilterSummary({cache, event}), @scope.map.getNotes(), @scope.map.getMail()]
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

            # note: multiple calls to redraw may occur, this ensures the center parcel is styled correctly
            if centerParcel && @showCenter
              $timeout =>
                $log.debug "center force!!!", centerParcel.rm_property_id
                lObject = @leafletDataMainMap.get(centerParcel.rm_property_id, '_parcelBase')?.lObject
                lObject?.setStyle(rmapsLayerFormattersService.Parcels.getStyle(centerParcel))
                @showCenter = false
              , 250

          @scope.$evalAsync =>
            $log.debug 'map.coffee - redraw calling results reset()'
            @scope.formatters.results?.reset()


      draw: (event, paths) =>
        verboseLogger.debug 'draw()'
        return if !@scope.map.isReady
        verboseLogger.debug 'isReady'

        $log.debug 'map.coffee - draw calling results reset()'
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
          ret = @redraw({cache:false, event})
        else
          ret = @redraw({event})

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
          lObject = @leafletDataMainMap.get(result.rm_property_id, 'saves')?.lObject ||
            @leafletDataMainMap.get(result.rm_property_id, 'favorites')?.lObject
          rmapsLayerFormattersService.MLS.setMarkerPriceOptions(result, @scope)
          lObject?.setIcon(new L.divIcon(result.icon))
          #update polygons immediately
          lObject = @leafletDataMainMap.get(result.rm_property_id, 'filterSummaryPoly')?.lObject

          lObject?.setStyle(rmapsLayerFormattersService.Parcels.getStyle(result))

          #make sure selectedResult is updated if it exists
          summary = @scope.map?.markers?.saves
          if @scope.selectedResult? and summary[@scope.selectedResult.rm_property_id]?
            delete @scope.selectedResult.savedDetails
            angular.extend(@scope.selectedResult, summary[@scope.selectedResult.rm_property_id])

          if wasPinned and !@scope.results[result.rm_property_id]
            result.isMousedOver = undefined
        @redraw({cache:false})

      favoritePropertyEventHandler: (event, eventData) =>
        result = eventData.property
        if result
          wasFavorite = result?.savedDetails?.isFavorite
          if wasFavorite and !@scope.results[result.rm_property_id]
            result.isMousedOver = undefined

          lObject = @leafletDataMainMap.get(result.rm_property_id, 'favorites')?.lObject ||
            @leafletDataMainMap.get(result.rm_property_id, 'saves')?.lObject
          rmapsLayerFormattersService.MLS.setMarkerPriceOptions(result, @scope)
          lObject?.setIcon(new L.divIcon(result.icon))

        @redraw({cache:false})

      setLocation: (position) =>
        $log.debug 'setLocation()', position
        {isMyLocation, coords} = position

        getZoom = (pos) =>
          pos.zoom = position.zoom ? rmapsZoomLevelService.getZoom(@scope) ? 14

        if position
          getZoom(coords)
          positionCenter = NgLeafletCenter coords

          if @scope.map.center.isEqual(positionCenter) && @scope.map.center.zoom == position.zoom
            return

          @showCenter = position.showCenter
        else
          position = @scope.previousCenter

        if isMyLocation
          @scope.map.markers.currentLocation.myLocation = rmapsLayerFormattersService.setCurrentLocationMarkerOptions(position)
          @redraw()

        getZoom(position)

        positionCenter.docWhere = 'rmapsMapFactory.zoomTo'
        @scope.map.center = positionCenter
        @scope.$evalAsync()

      #END PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
