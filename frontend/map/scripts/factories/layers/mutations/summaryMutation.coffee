### global _###
stampit = require 'stampit'
app = require '../../../app.coffee'

app.factory 'rmapSummaryMutation', (
$q
$log
rmapsLayerFormattersService
rmapsPropertiesService
rmapsZoomLevelStateFactory
) ->
  $log = $log.spawn 'rmapSummaryMutation'

  {setDataOptions, MLS} = rmapsLayerFormattersService

  _wrapGeomCenterJson = (obj) ->
    if !obj?.geometry_center?
      obj.geometry_center =
        coordinates: obj.coordinates
        type: obj.type
    obj

  stampit.methods

    mutateSummary: () ->
      if @isClusterResults()
        return
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

      # turn our price marker layer back on if zooming from parcel-level
      if @scope.zoomLevelService.isFromParcelZoom()
        Toggles.showPrices = true

      if !@isAnyParcel()
        overlays?.parcels?.visible = false
        Toggles.showAddresses = false
        overlays?.parcelsAddresses?.visible = false

      @

  .compose rmapsZoomLevelStateFactory
