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
        Toggles.showPrices = true
        Toggles.showAddresses = false
        overlays?.parcelsAddresses?.visible = false
        @promise = $q.resolve()
      @
  .compose rmapsZoomLevelStateFactory

app.factory 'rmapParcelResultsMutation',
($q, rmapSummaryResultsMutation, rmapsZoomLevelStateFactory, rmapsPropertiesService, rmapsLayerFormattersService, rmapsEmptyFilterData) ->

  stampit.methods
    handleGeoJsonResults: () ->
      rmapsPropertiesService.getFilterSummaryAsGeoJsonPolys(@hash, @mapState, @filters, @cache)
      .then (data) =>
        return if @isEmptyData()

        for key, model of data
          rmapsPropertiesService.updateProperty model

        @scope.map.geojson.filterSummaryPoly =
          data: data
          style: rmapsLayerFormattersService.Parcels.getStyle

    mutateParcel: () ->
      if @promise
        return @

      if !@isAnyParcel()
        return @

      overlays = @scope.map.layers.overlays
      Toggles = @scope.Toggles

      overlays?.parcels?.visible = not @isBeyondCartoDb()
      Toggles.showPrices = false
      Toggles.showAddresses = @isAddressParcel()
      overlays?.parcelsAddresses?.visible = Toggles.showAddresses

      @promise = @handleGeoJsonResults()
      @

  .compose rmapsZoomLevelStateFactory, rmapsEmptyFilterData

app.factory 'rmapsResultsFlow',
(rmapParcelResultsMutation, rmapClusterMutation, rmapSummaryResultsMutation, $log) ->
  $log = $log.spawn 'map:rmapsResultsFlow'
  flowFact = stampit
  .compose(rmapParcelResultsMutation, rmapClusterMutation, rmapSummaryResultsMutation)

  ({scope, filters, hash, mapState, data}) ->
    flow = flowFact({scope, filters, hash, mapState, data})

    flow.mutateCluster().mutateSummary().mutateParcel().promise
