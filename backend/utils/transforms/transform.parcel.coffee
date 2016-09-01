{validators} = require '../util.validation'
validation = require '../util.validation'


prepForRmPropertyId =
  apn:
    input: 'parcelapn'
    transform: [
      # for some reason, there are parcels without an APN that get ?, ??, or ??? instead
      validators.nullify(matcher: (s) -> !s || /^\?+$/.test(s))
      validators.string()
    ]
    required: true

  fipsCode:
    input: 'fips'
    transform: validators.string()
    required: true

  geometry:
    transform: validators.geojson(toCrs:true)
    required: true

  street_address_num:
    input: 'sthsnum'
    transform: validators.string()

  street_unit_num:
    input: 'stunitnum'
    transform: validators.string()


final =
  rm_property_id:
    input: false
    transform: validators.rm_property_id()
    required: true

  fips_code:
    input: false
    transform: validators.fips()
    required: true

  data_source_uuid:
    input: 'apn'
    required: true

  street_address_num: {}

  street_unit_num: {}

  geometry:
    required: true


validateAndTransform = (toTransform) ->
  validation.validateAndTransform toTransform, prepForRmPropertyId
  .then (valid) ->
    validation.validateAndTransform valid, final

module.exports = {
  prepForRmPropertyId
  final
  validateAndTransform
}
