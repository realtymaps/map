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

  _wrapGeomCenterJson = (obj) ->
    if !obj?.geometry_center?
      obj.geometry_center =
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

      singletons = @data?.singletons || @data
      setDataOptions(singletons, MLS.setMarkerPriceOptions)

      filterSummary = {}

      for key, model of singletons
        _wrapGeomCenterJson model
        rmapsPropertiesService.updateProperty model
        filterSummary[key] = model

      for key, group of @data?.groups
        if !group.grouped # skip if cached
          group.grouped = properties: _.values(group)
          group.grouped.name = key
          group.grouped.count = group.grouped.properties.length + 'U'
          group.grouped.forsale = _.filter(group.grouped.properties, 'status', 'for sale').length
          group.grouped.pending = _.filter(group.grouped.properties, 'status', 'pending').length
          group.grouped.sold = _.filter(group.grouped.properties, 'status', 'sold').length
          group.grouped.notforsale = 0

          MLS.setMarkerPriceGroupOptions(group)

          first = _.find(group)
          group.coordinates = first.coordinates
          group.type = first.type
          _wrapGeomCenterJson(group)
          group.geometry = group.geometry_center

        filterSummary["#{group.grouped.name}:#{group.grouped.forsale}:#{group.grouped.pending}:#{group.grouped.sold}"] = group

      @scope.map.markers.filterSummary = filterSummary

      $log.debug @scope.map.markers.filterSummary

      if @scope.zoomLevelService.isFromParcelZoom()
        Toggles.showPrices = true
      if !@isAnyParcel()
        overlays?.parcels?.visible = false
        Toggles.showAddresses = false
        overlays?.parcelsAddresses?.visible = false
        @promise = $q.resolve()
      @
  .compose rmapsZoomLevelStateFactory

app.factory 'rmapParcelResultsMutation',
($q, $log, rmapSummaryResultsMutation, rmapsZoomLevelStateFactory, rmapsPropertiesService, rmapsLayerFormattersService, rmapsEmptyFilterData) ->
  $log = $log.spawn 'rmapParcelResultsMutation'
  stampit.methods
    handleGeoJsonResults: (data) ->
      rmapsPropertiesService.getFilterSummaryAsGeoJsonPolys(@hash, @mapState, @filters, data)
      .then (data) =>
        return if @isEmptyData()

        $log.debug data
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
      Toggles.showAddresses = @isAddressParcel()
      overlays?.parcelsAddresses?.visible = Toggles.showAddresses

      @promise = @handleGeoJsonResults(@data?.singletons)
      @

  .compose rmapsZoomLevelStateFactory, rmapsEmptyFilterData

app.factory 'rmapsResultsFlow',
(rmapParcelResultsMutation, rmapClusterMutation, rmapSummaryResultsMutation, $log) ->
  $log = $log.spawn 'map:rmapsResultsFlow'
  flowFact = stampit
  .compose(rmapParcelResultsMutation, rmapClusterMutation, rmapSummaryResultsMutation)

  ({scope, filters, hash, mapState, data, cache}) ->
    flow = flowFact({scope, filters, hash, mapState, data})

    promise = flow.mutateCluster().mutateSummary().mutateParcel().promise

    #make the promise apparent as an undefined promise will just pass through and make
    #q.all a nightmare to debug. This was the main big bug originally in here
    if !promise
      throw new Error 'rmapsResultsFlow promise is undefined'
    promise
