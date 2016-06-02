###globals _###
stampit = require 'stampit'
app = require '../app.coffee'

app.factory 'rmapsEmptyFilterData', () ->
  stampit.methods
    isEmptyData: () ->
      !@data? or _.isString @data


###
  overall flow:
  if this.promise exists then the mutation has been handled.
###
app.factory 'rmapClusterMutation', ($q, rmapsLayerFormattersService, rmapsPropertiesService, rmapsEmptyFilterData) ->
  {MLS} = rmapsLayerFormattersService

  stampit.methods
    isClusterResults: () ->
      Object.prototype.toString.call(@data) is '[object Array]' and !@isEmptyData() and !@promise

    mutateCluster: () ->
      if @isClusterResults()
        @scope.map.markers.filterSummary = {}
        clusters = {}
        for k, model of @data
          # Need to ensure unique keys for markers so old ones get removed, new ones get added. Dashes must be removed.
          clusters["#{model.count}:#{model.lat}:#{model.lng}".replace('-','N')] = MLS.setMarkerManualClusterOptions(model)
        @scope.map.markers.backendPriceCluster = clusters
        @promise = $q.resolve()
      @

  .compose(rmapsEmptyFilterData)

app.factory 'rmapSummaryResultsMutation',
($q, rmapsLayerFormattersService, rmapsPropertiesService, rmapsZoomLevelStateFactory) ->
  {setDataOptions, MLS} = rmapsLayerFormattersService

  _wrapGeomPointJson = (obj) ->
    unless obj?.geom_point_json
      obj.geom_point_json =
        coordinates: obj.coordinates
        type: obj.type
    obj

  stampit.methods

    mutateSummary: () ->
      if @promise
        return @

      overlays = @scope.map.layers.overlays
      Toggles = @scope.Toggles

      @scope.map.markers.backendPriceCluster = {}
      setDataOptions(@data, MLS.setMarkerPriceOptions)

      for key, model of @data
        _wrapGeomPointJson model
        rmapsPropertiesService.updateProperty model

      @scope.map.markers.filterSummary = @data

      if !@isAnyParcel()
        overlays?.parcels?.visible = false
        if @scope.zoomLevelService.isFromPriceZoom()
          Toggles.showPrices = true
        Toggles.showAddresses = false
        overlays?.parcelsAddresses?.visible = false
        @promise = $q.resolve()
      @
  .compose rmapsZoomLevelStateFactory

app.factory 'rmapParcelResultsMutation',
($q, rmapSummaryResultsMutation, rmapsZoomLevelStateFactory, rmapsPropertiesService, rmapsLayerFormattersService, rmapsEmptyFilterData) ->

  stampit.methods
    handleGeoJsonResults: (cache) ->
      rmapsPropertiesService.getFilterSummaryAsGeoJsonPolys(@hash, @mapState, @filters, cache)
      .then (data) =>
        return if @isEmptyData()

        @scope.map.geojson.filterSummaryPoly =
          data: data
          style: rmapsLayerFormattersService.Parcels.getStyle

    mutateParcel: (cache) ->
      if @promise
        return @

      if !@isAnyParcel()
        return @

      overlays = @scope.map.layers.overlays
      Toggles = @scope.Toggles

      overlays?.parcels?.visible = not @isBeyondCartoDb()
      Toggles.showAddresses = @isAddressParcel()
      overlays?.parcelsAddresses?.visible = Toggles.showAddresses

      @promise = @handleGeoJsonResults(cache)
      @

  .compose rmapsZoomLevelStateFactory, rmapsEmptyFilterData

app.factory 'rmapsResultsFlow',
(rmapParcelResultsMutation, rmapClusterMutation, rmapSummaryResultsMutation, $log) ->
  $log = $log.spawn 'map:rmapsResultsFlow'
  flowFact = stampit
  .compose(rmapParcelResultsMutation, rmapClusterMutation, rmapSummaryResultsMutation)

  ({scope, filters, hash, mapState, data, cache}) ->
    flow = flowFact({scope, filters, hash, mapState, data})

    promise = flow.mutateCluster().mutateSummary().mutateParcel(cache).promise

    #make the promise apparent as an undefined promise will just pass through and make
    #q.all a nightmare to debug. This was the main big bug originally in here
    if !promise
      throw new Error 'rmapsResultsFlow promise is undefined'
    promise
