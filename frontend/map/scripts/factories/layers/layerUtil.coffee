stampit = require 'stampit'
app = require '../../app.coffee'

app.factory 'rmapsLayerUtil', () ->
  stampit.methods
    isEmptyData: () ->
      !@data? or typeof @data == 'string'

app.service 'rmapsLayerUtilService', (rmapsLayerUtil) ->
  instance = stampit.compose(rmapsLayerUtil)

  filterParcelsFromSummary = ({parcels, props}) ->
    if parcels?.features?.length
      #filter out dupes where we don't need a blank parcel under a property parcel
      parcels.features = parcels.features.filter (f) ->
        !!!props.features.find (p) ->
          p.rm_property_id == f.rm_property_id

    parcels?.features

  {
    filterParcelsFromSummary
    isEmptyData: instance.isEmptyData
  }
