app = require '../app.coffee'

require '../constants/parcel_enums.coffee'

app.service 'Parcels'.ourNs(), [
  'uiGmapLogger','ParcelEnums'.ourNs(),
  ($log, ParcelEnums) ->
    fill:(parcel) ->
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
]
