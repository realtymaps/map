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

  filterParcelsFromSummary = ({parcels, props}) ->
    if parcels?.features?.length
      #filter out dupes where we don't need a blank parcel under a property parcel
      parcels.features = parcels.features.filter (f) ->
        !!!props.features.find (p) ->
          p.rm_property_id == f.rm_property_id

    parcels?.features

  parcelTileVisSwitching = ({scope, event}) ->
    overlays = scope.map.layers.overlays
    Toggles = scope.Toggles

    $log.debug -> "@@@@ event @@@@"
    $log.debug -> event

    if event == 'zoomend'
      overlays?.parcels?.visible = not rmapsZoomLevelService.isBeyondCartoDb(scope.map.center.zoom)
      Toggles.showAddresses = rmapsZoomLevelService.isAddressParcel(scope.map.center.zoom, scope)
      overlays?.parcelsAddresses?.visible = Toggles.showAddresses

    return

  {
    filterParcelsFromSummary
    parcelTileVisSwitching
    isEmptyData: instance.isEmptyData
  }
