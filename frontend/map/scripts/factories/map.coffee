###globals L,_,angular###
app = require '../app.coffee'
{NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')
Point = require('../../../../common/utils/util.geometries.coffee').Point

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
app.factory 'rmapsMapFactory',
  ($log, $timeout, $q, $rootScope, $http, rmapsBaseMapFactory,
  rmapsPropertiesService, rmapsEventConstants, rmapsLayerFormattersService, rmapsMainOptions,
  rmapsFilterManagerService, rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsZoomLevelService,
  rmapsPopupLoaderService, leafletData, rmapsControlsService, rmapsRenderingService, rmapsMapEventsHandlerService, rmapsLeafletObjectFetcherFactory) ->

    leafletDataMainMap = new rmapsLeafletObjectFetcherFactory('mainMap')
    limits = rmapsMainOptions.map

    normal = $log.spawn("map:factory:normal")
    verboseLogger = $log.spawn("map:factory:verbose")
    $log = normal

    _initToggles = ($scope, toggles) ->
      return unless toggles?
      _handleMoveToMyLocation = (position) ->
        if position
          position = position.coords
        else
          position = $scope.previousCenter

        position.zoom = position.zoom ? rmapsZoomLevelService.getZoom($scope) ? 14
        $scope.map.center = NgLeafletCenter position
        $scope.$evalAsync()

      if toggles?.setLocationCb?
        toggles.setLocationCb(_handleMoveToMyLocation)
      $scope.Toggles = toggles

    class Map extends rmapsBaseMapFactory

      constructor: ($scope) ->
        _overlays = require '../utils/util.layers.overlay.coffee' #don't get overlays until your logged in
        super $scope, limits.options, limits.redrawDebounceMilliSeconds, 'map' ,'mainMap'

        _initToggles $scope, limits.toggles

        $scope.zoomLevelService = rmapsZoomLevelService
        self = @

        #
        # Property Button events
        #
        $rootScope.$onRootScope rmapsEventConstants.map.centerOnProperty, (event, result) ->
          self.zoomTo result, false

        $rootScope.$onRootScope rmapsEventConstants.map.zoomToProperty, (event, result, doChangeZoom) ->
          self.zoomTo result, doChangeZoom

        $rootScope.$onRootScope rmapsEventConstants.update.properties.pin, self.pinPropertyEventHandler

        $rootScope.$onRootScope rmapsEventConstants.update.properties.favorite, self.favoritePropertyEventHandler

        #
        # End Property Button Events
        #

        leafletData.getMap('mainMap').then () =>

          $scope.$watch 'Toggles.showPrices', (newVal) ->
            $scope.map.layers.overlays?.filterSummary?.visible = newVal

          $scope.$watch 'Toggles.showAddresses', (newVal) ->
            if(_.get($scope, 'map.layers.overlays.parcelsAddresses')?)
              $scope.map.layers.overlays.parcelsAddresses.visible = newVal

          $scope.$watch 'Toggles.propertiesInShapes', (newVal) =>
            $rootScope.propertiesInShapes = newVal
            @redraw()

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

        [rmapsEventConstants.map.filters.updated, rmapsEventConstants.map.mainMap.redraw].forEach (eventName) =>
          $rootScope.$onRootScope eventName, =>
            @redraw()

        $rootScope.$onRootScope rmapsEventConstants.map.center, (evt, location) ->
          $scope.Toggles.setLocation location

        @layerFormatter = rmapsLayerFormattersService

        @pinPropertyEventHandler = (event, eventData) =>
          result = eventData.property

          if result
            wasSaved = result?.savedDetails?.isSaved

            # Handle the leaflet object
            lObject = leafletDataMainMap.get(result.rm_property_id, 'filterSummary')?.lObject
            rmapsLayerFormattersService.MLS.setMarkerPriceOptions(result, @scope)
            lObject?.setIcon(new L.divIcon(result.icon))

            #make sure selectedResult is updated if it exists
            summary = @scope.map?.markers?.filterSummary
            if @scope.selectedResult? and summary[@scope.selectedResult.rm_property_id]?
              delete @scope.selectedResult.savedDetails
              angular.extend(@scope.selectedResult, summary[@scope.selectedResult.rm_property_id])

            if wasSaved and !@scope.results[result.rm_property_id]
              result.isMousedOver = undefined

          @redraw(false)

        @favoritePropertyEventHandler = (event, eventData) =>
          result = eventData.property

          if result
            wasFavorite = result?.savedDetails?.isFavorite
            if wasFavorite and !@scope.results[result.rm_property_id]
              result.isMousedOver = undefined

            lObject = leafletDataMainMap.get(result.rm_property_id, 'filterSummary')?.lObject
            rmapsLayerFormattersService.MLS.setMarkerPriceOptions(result, @scope)
            lObject?.setIcon(new L.divIcon(result.icon))


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
      clearBurdenLayers: () =>
        if @map? and not rmapsZoomLevelService.isParcel(@scope.map.center.zoom)
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
        {Toggles} = @scope

        # result-count-based clustering, backend will either give clusters or summary.  Get and test here.
        # no need to query backend if no status is designated (it would error out by default right now w/ no status constraint)
        filters = rmapsFilterManagerService.getFilters()
        # $log.debug filters
        unless filters?.status?
          @clearFilterSummary()
          return promises

        # $log.debug "hash: #{@hash}"
        # $log.debug "mapState: #{@mapState}"
        #NOTE THE PROMISE of getFilterResults being coupled with the mutated (.then) is important otherwise the workflow gets messed up
        p = rmapsPropertiesService.getFilterResults(@hash, @mapState, filters, cache)
        .then (data) =>

          if Object.prototype.toString.call(data) is '[object Array]'
            if !data? or _.isString data
              return $q.resolve()
            $q.resolve @handleClusterResults(data)

          else
            #needed for results list, rendering price markers, and address Markers
            #depending on zoom we want address or price
            #the data structure is the same (do we clone and hide one?)
            #or do we have the results list view grab one that exists with items?
            if !data? or _.isString data
              return $q.resolve()
            $q.resolve @handleSummaryResults(data)

            if @isParcel() or @isAddressParcel()

              if @isAddressParcel()
                if @isBeyondCartoDb()
                  zoomLvl = 'addressParcelBeyondCartoDB'
                else
                  zoomLvl = 'addressParcel'

              else if @isParcel()
                zoomLvl = 'parcel'

              overlays?.parcels?.visible = not @isBeyondCartoDb()
              Toggles.showPrices = false
              Toggles.showAddresses = @isAddressParcel()
              overlays?.parcelsAddresses?.visible = Toggles.showAddresses

              return @handleGeoJsonResults(filters, cache)

            else
              zoomLvl = 'price'

              overlays?.parcels?.visible = false
              Toggles.showPrices = true
              Toggles.showAddresses = false
              overlays?.parcelsAddresses?.visible = false
              return $q.resolve()

            # $log.debug "drawFilterSummary zoom=#{@scope.map.center.zoom} (@#{zoomLvl})"

        promises.push p
        promises

      isZoomLevel: (key, doSetState) =>
        if doSetState
          return rmapsZoomLevelService[key](@scope.map.center.zoom, @scope)
        rmapsZoomLevelService[key](@scope.map.center.zoom)

      isAddressParcel: (doSetState) =>
        @isZoomLevel('isAddressParcel', doSetState)

      isParcel: () =>
        @isZoomLevel('isParcel')

      isBeyondCartoDb: () =>
        @isZoomLevel('isBeyondCartoDb')

      showClientSideParcels: () ->
        ###
        isBeyondCartoDb is what is important here as we are beyond the context of what
        cartodb can show us server side. We no will put the work load on the client for parcels.
        However, this is ok as we should be zoomed in a significant amount where (n) parcels should be
        smaller.
        ###
        (@isAddressParcel(true) or @isParcel()) and @isBeyondCartoDb()

      showVectorPolys: () ->
        !@showClientSidePolys()

      redraw: (cache = true) =>
        promises = []

        #consider renaming parcels to addresses as that is all they are used for now
        if @showClientSideParcels()
          verboseLogger.debug 'isAddressParcel'
          promises.push rmapsPropertiesService.getParcelBase(@hash, @mapState, cache).then (data) =>
            return unless data?
            @scope.map.geojson.parcelBase =
              data: data
              style: @layerFormatter.Parcels.style

            $log.debug "addresses count to draw: #{data?.features?.length}"

        else
          verboseLogger.debug 'not, isAddressParcel'
          rmapsZoomLevelService.dblClickZoom.enable(@scope)
          promises.push @clearBurdenLayers()

        promises = promises.concat @drawFilterSummary(cache), [@scope.map.getNotes()]

        $q.all(promises).then =>
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

      openWindow: (model, lTriggerObject) =>
        rmapsPopupLoaderService.load(@scope, @map, model, lTriggerObject)

      closeWindow: ->
        rmapsPopupLoaderService.close()

      centerOn: (result) =>
        @zoomTo(result, false)

      zoomTo: (result, doChangeZoom) ->
        console.log  "CAUGHT zoomToProperty event"
        return if not result?.coordinates?

        resultCenter = new Point(result.coordinates[1],result.coordinates[0])
        old = _.cloneDeep @scope.map.center
        resultCenter.zoom = old.zoom
        @scope.map.center = resultCenter
        return unless doChangeZoom
        zoomLevel = @scope.options.zoomThresh.addressParcel
        zoomLevel = @scope.map.center.zoom if @scope.map.center.zoom > @scope.options.zoomThresh.addressParcel
        @scope.map.center.zoom = zoomLevel

        resultCenter.zoom = 20 if @scope.satMap?

      #END PUBLIC HANDLES /////////////////////////////////////////////////////////////////////////////////////////
