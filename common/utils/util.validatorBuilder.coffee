_ = require 'lodash'

baseDefaults =
    alias: 'Unnamed'
    required: false
    config: {},
    input: ''
    valid: () ->
      !@.required || @.input

baseRules =
  acres:
    alias: 'Acres'

  address:
    alias: 'Address'
    required: true
    input: {}
    group: 'general'
    valid: () ->
      @.input.city && @.input.state && (@.input.zip || @.input.zip9) &&
      ((@.input.streetName && @.input.streetNum) || @.input.streetFull)

  baths_full:
    alias: 'Baths Full'

  bedrooms:
    alias: 'Bedrooms'

  days_on_market:
    alias: 'Days on Market'
    required: true
    input: []
    valid: () ->
      @.input[0] || @.input[1]

  fips_code:
    alias: 'FIPS code'
    required: true
    input: {}
    valid: () ->
      @.input.stateCode && @.input.county

  hide_address:
    alias: 'Hide Address'

  hide_listing:
    alias: 'Hide Listing'

  parcel_id:
    alias: 'Parcel ID'
    required: true
    config:
      stripFormatting: true

  price:
    alias: 'Price'
    required: true

  rm_property_id:
    alias: 'Property ID'
    required: true
    input: {}

  sqft_finished:
    alias: 'Finished Sq Ft'

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

  discontinued_date:
    alias: 'Discontinued Date'

  mls_uuid:
    alias: 'MLS Number'
    required: true

retsDefaults =
  type:
    name: 'unknown'
    label: 'Unkown'
  config: {}
  getValidator: () -> @.type.name

retsRules =
  Int:
    type:
      name: 'integer'
      label: 'Number'
    config:
      nullZero: true
  Decimal:
    type:
      name: 'float'
      label: 'Number'
    config:
      nullZero: true
  Long:
    type:
      name: 'float'
      label: 'Number'
    config:
      nullZero: true
  Character:
    type:
      name: 'string'
    config:
      nullEmpty: true
  DateTime:
    type:
      name: 'datetime'
      label: 'Date and Time'
  Boolean:
    type:
      name: 'boolean'
      label: 'Yes/No'
    getValidator: () -> 'nullify'

_getValidationString = (type, vOptions) ->
  vOptionsStr = if vOptions then JSON.stringify(vOptions) else ''
  "validators.#{type}(#{vOptionsStr})"

updateTransform = (field) ->
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
      _getValidationString(field.getValidator(), vOptions)

updateRule = (rule) ->
  _.defaultsDeep rule, retsRules[rule.DataType], retsDefaults
  if rule.type?.name == 'string'
    if rule.Interpretation == 'Lookup'
      rule.type.label = 'Restricted Text (single value)'
    else if rule.Interpretation == 'LookupMulti'
      rule.type.label = 'Restricted Text (multiple values)'
    else
      rule.type.label = 'User-Entered Text'
  updateTransform rule

updateBase = (rule) ->
  _.defaultsDeep rule, baseRules[rule.output], baseDefaults
  updateTransform rule

module.exports =
  baseRules: baseRules
  updateRule: updateRule
  updateBase: updateBase