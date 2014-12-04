app = require '../app.coffee'

require '../constants/parcel_enums.coffee'

app.service 'LayerFormatters'.ourNs(), [
  'uiGmapLogger', 'ParcelEnums'.ourNs(),
  ($log, ParcelEnums) ->
    Parcels:
      fill: (parcel) ->
        color = switch parcel.model.for_sale
          when ParcelEnums.forSale.Not
            '#2c8aa7'
          when ParcelEnums.forSale.NotRecent
            '#852d1d'
          when ParcelEnums.forSale.NotPending
            '#d48c0e'
          when ParcelEnums.forSale.Active
            '#2fa02c'
          else
            '#7e847f'

        color: color
        opacity: '.65'
    MLS:
      labelFromPrice: (mls) ->
        return {} unless mls
        icon: ' '
        labelContent: mls.list_price
        labelAnchor: "0 0"
        #add checks to change labelCss based on Price
        labelClass: "address-label"

      labelFromStreetNum: (p) ->
        return {} unless p
#        icon: ' '
        labelContent: p.street_num
        labelAnchor: "0 0"
        labelClass: "address-label"

]
