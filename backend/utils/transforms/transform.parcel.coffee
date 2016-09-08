{validators} = require '../util.validation'
validation = require '../util.validation'


prepForRmPropertyId =
  apn:
    input: 'parcelapn'
    transform: [
      # for now, just kill any parcel that had OCR errors in the APN -- but eventually we might want to pull them in
      # with some sort of flag value so we can run a task to find them and try to fix the APN based on e.g. blackknight
      validators.string(stripFormatting: true)
      validators.nullify(matcher: (s) -> !s || s.indexOf('?') != -1 || /^0+$/.test(s))
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
    input: false
    transform: validators.rm_property_id()
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
