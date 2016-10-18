###globals _, L###
stampit = require 'stampit'
app = require '../../app.coffee'

app.factory 'rmapsLayerUtil', () ->
  stampit.methods
    isEmptyData: () ->
      !@data? or typeof @data == 'string'

app.service 'rmapsLayerUtilService', (
$log
rmapsLayerUtil
rmapsZoomLevelService) ->
  $log = $log.spawn('rmapsLayerUtilService')

  instance = stampit.compose(rmapsLayerUtil)

  isFirstTileSwitch = true

  getPolygonFactory = (geometry) ->
    if Array.isArray geometry.coordinates[0]
      return L.multiPolygon
    L.polygon

  createPolygon = (geometry) ->
    getPolygonFactory(geometry)(geometry.coordinates)


  filterParcelsFromSummary = ({parcels, props}) ->
    if parcels?.features?.length

      #filter out dupes where we don't need a blank parcel under a property parcel
      parcels.features = parcels.features.filter (f) ->
        !_.any props.features, (p) ->
          if p.rm_property_id == f.rm_property_id #only works if parcels and data_combined are synced
            return true
          createPolygon(f.geometry).getBounds().contains(p.geometry_center.coordinates)

    parcels?.features

  parcelTileVisSwitching = ({scope, event}) ->
    overlays = scope.map.layers.overlays
    Toggles = scope.Toggles

    $log.debug -> "@@@@ event @@@@"
    $log.debug -> event

    if event == 'zoomend' || isFirstTileSwitch
      if overlays?
        isFirstTileSwitch = false
        overlays.parcels?.visible = not rmapsZoomLevelService.isBeyondCartoDb(scope.map.center.zoom)
        overlays.parcelsAddresses?.visible = Toggles.showAddresses

      if Toggles?
        Toggles.showAddresses = rmapsZoomLevelService.isAddressParcel(scope.map.center.zoom, scope)

    return

  {
    filterParcelsFromSummary
    parcelTileVisSwitching
    isEmptyData: instance.isEmptyData
  }
