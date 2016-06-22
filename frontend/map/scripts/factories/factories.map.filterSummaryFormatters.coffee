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
($q, $log, rmapsLayerFormattersService, rmapsPropertiesService, rmapsZoomLevelStateFactory) ->
  $log = $log.spawn 'rmapSummaryResultsMutation'

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
      setDataOptions(@data?.singletons, MLS.setMarkerPriceOptions)

      for key, model of @data?.singletons
        _wrapGeomPointJson model
        rmapsPropertiesService.updateProperty model

      for key, group of @data?.groups
        group.grouped = properties: _.values(group)
        group.grouped.name = key
        group.grouped.count = group.grouped.properties.length + 'C'
        group.grouped.forsale = _.filter(group.grouped.properties, 'status', 'forsale').length
        group.grouped.pending = _.filter(group.grouped.properties, 'status', 'pending').length
        group.grouped.sold = _.filter(group.grouped.properties, 'status', 'sold').length
        group.grouped.notforsale = 0
        $log.debug group.grouped

        first = _.find(group)
        group.coordinates = first.coordinates
        group.type = first.type
        _wrapGeomPointJson(group)

      setDataOptions(@data?.groups, MLS.setMarkerCondoOptions)

      @scope.map.markers.filterSummary = _.assign(@data?.singletons, @data?.groups)

      $log.debug @scope.map.markers.filterSummary

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
    handleGeoJsonResults: (data) ->
      rmapsPropertiesService.getFilterSummaryAsGeoJsonPolys(@hash, @mapState, @filters, data?.singletons)
      .then (data) =>
        return if @isEmptyData()

        @scope.map.geojson.filterSummaryPoly =
          data: data
          style: rmapsLayerFormattersService.Parcels.getStyle

    mutateParcel: (data) ->
      if @promise
        return @

      if !@isAnyParcel()
        return @

      overlays = @scope.map.layers.overlays
      Toggles = @scope.Toggles

      overlays?.parcels?.visible = not @isBeyondCartoDb()
      Toggles.showAddresses = @isAddressParcel()
      overlays?.parcelsAddresses?.visible = Toggles.showAddresses

      @promise = @handleGeoJsonResults(data)
      @

  .compose rmapsZoomLevelStateFactory, rmapsEmptyFilterData

app.factory 'rmapsResultsFlow',
(rmapParcelResultsMutation, rmapClusterMutation, rmapSummaryResultsMutation, $log) ->
  $log = $log.spawn 'map:rmapsResultsFlow'
  flowFact = stampit
  .compose(rmapParcelResultsMutation, rmapClusterMutation, rmapSummaryResultsMutation)

  ({scope, filters, hash, mapState, data, cache}) ->
    flow = flowFact({scope, filters, hash, mapState, data})

    promise = flow.mutateCluster().mutateSummary().mutateParcel(data).promise

    #make the promise apparent as an undefined promise will just pass through and make
    #q.all a nightmare to debug. This was the main big bug originally in here
    if !promise
      throw new Error 'rmapsResultsFlow promise is undefined'
    promise
