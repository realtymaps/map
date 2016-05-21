{validators} = require '../util.validation'
validation = require '../util.validation'


prepForRmPropertyId =
  apn:
    input: 'parcelapn'
    transform: validators.string()
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
    isRoot: true
    transform: validators.rm_property_id()
    required: true

  fips_code:
    isRoot: true
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
