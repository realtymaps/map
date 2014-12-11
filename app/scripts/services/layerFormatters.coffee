app = require '../app.coffee'

require '../constants/parcel_enums.coffee'
sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.service 'LayerFormatters'.ourNs(), [
  'uiGmapLogger', 'ParcelEnums'.ourNs(),
  ($log, ParcelEnums) ->
    colors = {}
    colors[ParcelEnums.status.sold] = '#2c8aa7'
    colors[ParcelEnums.status.pending] = '#d48c0e'
    colors[ParcelEnums.status.forSale] = '#2fa02c'
    colors['default'] = 'rgba(105, 245, 233, 0.08)' #or '#7e847f'?


    markersIcon = {}
    markersIcon[ParcelEnums.status.sold] = '../assets/map_marker_out_pink_64.png'
    markersIcon[ParcelEnums.status.pending] = '../assets/map_marker_out_azure_64.png'
    markersIcon[ParcelEnums.status.forSale] = '../assets/map_marker_out_green_64.png'
    markersIcon['default'] = ''

    markerContentTemplate = '<h4><span class="label label-%s">%s</span></h4>'
    markersBSLabel = {}
    markersBSLabel[ParcelEnums.status.sold] = 'danger'
    markersBSLabel[ParcelEnums.status.pending] = 'warning'
    markersBSLabel[ParcelEnums.status.forSale] = 'success'
    markersBSLabel['default'] = 'info'


    formatMarkerContent = (label, content) ->
      sprintf markerContentTemplate, label, content

    formatStatusMarkerContent = (status, content) ->
      formatMarkerContent markersBSLabel[status] or markersBSLabel['default'], content

    Parcels:
      fill: (parcel) ->
        return {} unless parcel
        color: colors[parcel.model.rm_status] or colors['default']
        opacity: '.65'

      labelFromStreetNum: (parcel) ->
        return {} unless parcel
        icon: ' '
        labelContent: formatMarkerContent 'default', parcel.street_address_num
        labelAnchor: "20 10"

    MLS:
      markerOptionsFromForSale: (mls) ->
        return {} unless mls
        formattedPrice = casing.upper numeral(mls.price).format('0.00a'), '.'
        ret =
          icon: markersIcon[mls.rm_status] or markersIcon['default']
          labelContent: formatStatusMarkerContent mls.rm_status, formattedPrice
          labelAnchor: "30 100"
        ret
]
