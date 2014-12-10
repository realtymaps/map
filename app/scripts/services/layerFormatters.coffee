app = require '../app.coffee'

require '../constants/parcel_enums.coffee'

app.service 'LayerFormatters'.ourNs(), [
  'uiGmapLogger', 'ParcelEnums'.ourNs(),
  ($log, ParcelEnums) ->
    colors = {}
    colors[ParcelEnums.status.sold] = '#2c8aa7'
    colors[ParcelEnums.status.pending] = '#d48c0e'
    colors[ParcelEnums.status.forSale] = '#2fa02c'
    colors['default'] = '#transparent' #or '#7e847f'?

    Parcels:
      fill: (parcel) ->
        color: colors[parcel.model.rm_status] || colors['default']
        opacity: '.65'

      labelFromStreetNum: (parcel) ->
        return {} unless parcel
        icon: ' '
        labelContent: parcel.street_address_num
        labelAnchor: "0 0"
        labelClass: "address-label"

    MLS:
      labelFromPrice: (mls) ->
        return {} unless mls
        icon: ' '
        labelContent: mls.list_price
        labelAnchor: "0 0"
        #add checks to change labelCss based on Price
        labelClass: "address-label"
]
