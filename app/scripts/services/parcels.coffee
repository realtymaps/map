app = require '../app.coffee'

require '../constants/parcel_enums.coffee'


app.service 'Parcels'.ourNs(), [
  'uiGmapLogger','ParcelEnums'.ourNs(),
  ($log, ParcelEnums) ->
    colors = {}
    colors[ParcelEnums.status.sold] = '#822'
    colors[ParcelEnums.status.pending] = '#D81'
    colors[ParcelEnums.status.forSale] = '#2A2'
    colors['default'] = '#transparent'

    fill:(parcel) ->
      color: colors[parcel.model.rm_status] || colors['default']
      opacity: '.65'
]
