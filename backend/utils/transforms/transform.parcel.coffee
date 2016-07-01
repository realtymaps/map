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

finalizeParcelAsDataCombined =
  geometry_raw: input: 'geometry_raw'
  geometry: input: 'geometry'
  geometry_center: input: 'geometry_center'

execFinalizeParcelAsDataCombined = (finalizedParcel) ->
  validation.validateAndTransform finalizedParcel, finalizeParcelAsDataCombined

validateAndTransform = (toTransform) ->
  validation.validateAndTransform toTransform, prepForRmPropertyId
  .then (valid) ->
    validation.validateAndTransform valid, final

module.exports = {
  prepForRmPropertyId
  final
  validateAndTransform
  finalizeParcelAsDataCombined
  execFinalizeParcelAsDataCombined
}
