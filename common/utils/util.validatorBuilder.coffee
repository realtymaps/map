_ = require 'lodash'

baseRules =
  acres:
    alias: 'Acres'
    required: true
  address:
    alias: 'Address'
    required: true
    input: {}
    group: 'general'
  baths_full:
    alias: 'Baths Full'
    required: true
  bedrooms:
    alias: 'Bedrooms'
    required: true
  days_on_market:
    alias: 'Days on Market'
    required: true
    input: []
  fips_code:
    alias: 'FIPS code'
    required: true
    input: []
  hide_address:
    alias: 'Hide Address'
    required: false
  hide_listing:
    alias: 'Hide Listing'
    required: false
  parcel_id:
    alias: 'Parcel ID'
    required: true
  price:
    alias: 'Price'
    required: true
  rm_property_id:
    alias: 'Property ID'
    required: true
    input: []
  sqft_finished:
    alias: 'Finished Sq Ft'
    required: true
  status:
    alias: 'Status'
    required: true
  status_display:
    alias: 'Status Display'
    required: true
    group: 'general'
  substatus:
    alias: 'Sub-Status'
    required: true
  close_date:
    alias: 'Close Date'
    required: false
  discontinued_date:
    alias: 'Discontinued Date'
    required: false
  mls_uuid:
    alias: 'MLS Number'
    required: true

lookupType = (field) ->
  types =
    Int:
      name: 'integer'
      label: 'Number'
    Decimal:
      name: 'float'
      label: 'Number'
    Long:
      name: 'float'
      label: 'Number'
    Character:
      name: 'string'
    DateTime:
      name: 'datetime'
      label: 'Date and Time'
    Boolean:
      name: 'boolean'
      label: 'Yes/No'

  type = types[field.DataType]

  if type?.name == 'string'
    if field.Interpretation == 'Lookup'
      type.label = 'Restricted Text (single value)'
    else if field.Interpretation == 'LookupMulti'
      type.label = 'Restricted Text (multiple values)'
    else
      type.label = 'User-Entered Text'

  type

_getValidationString = (type, vOptions) ->
  vOptionsStr = if vOptions then JSON.stringify(vOptions) else ''
  "validators.#{type}(#{vOptionsStr})"

getTransform = (field) ->
  #   options:
  #
  #     type: integer | float | string | fips | map | currency | ...
  #       Maps to a validation handler.
  #       EG if type = "integer", we will expect:
  #       "validation.integer"
  #       If in future these seem arcane, like "rm_property_id",
  #         we can create a map
  #     vOptions:
  #       validation options to be nested into validation calls
  #     map:
  #       key-value mapping for map field
  #       present if type is map
  #

  if field.config?.advanced
    return

  reserved = [ 'advanced' ]
  vOptions = _.pick field.config, (v, k) -> v? && v != '' && !_.contains(reserved, k)

  field.transform =
  switch field.output
    when 'address'
      _getValidationString('address', vOptions)

    when 'status', 'substatus', 'status_display'
      _getValidationString('map', map: vOptions.map ? {}, passUnmapped: true)

    when 'parcel_id', 'mls_uuid'
      _getValidationString('string', vOptions)

    when 'days_on_market'
      'validators.pickFirst({criteria: validators.integer()})'

    when 'baths_full', 'bedrooms', 'sqft_finished'
      _getValidationString('integer', vOptions)

    when 'price'
      _getValidationString('currency', vOptions)

    when 'rm_property_id'
      _getValidationString('rm_property_id', vOptions)

    when 'fips_code'
      _getValidationString('fips', vOptions)

    when 'acres'
      _getValidationString('float', vOptions)

    when 'hide_address', 'hide_listing'
      _getValidationString('boolean', vOptions)

    when 'close_date', 'discontinued_date'
      _getValidationString('datetime', vOptions)

    else
      type = lookupType(field)
      if type.name == 'boolean'
        _getValidationString('nullify', vOptions)
      else
        _getValidationString(type?.name, vOptions)

validateBase = (field) ->
  # Ensure input is appropriate type before validating
  defaults = baseRules[field.output]
  if defaults
    if !field.input?
      field.input = defaults.input || ''
    field.alias = defaults.alias
  input = field.input
  switch field.output
    when 'address'
      field.valid = input.city && input.state && (input.zip || input.zip9) &&
       ((input.streetName && input.streetNum) || input.streetFull)
    when 'days_on_market'
      field.valid = input[0] || input[1]
    when 'fips_code'
      field.valid = input[0] && input[1]
    when 'rm_property_id'
      field.valid = input[0] && input[1] && input[2]
    else
      field.valid = !field.required || !!input
  field.valid = !!field.valid

module.exports =
  lookupType: lookupType
  getTransform: getTransform
  baseRules: baseRules
  validateBase: validateBase