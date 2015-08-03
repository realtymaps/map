_ = require 'lodash'

ruleDefaults =
  alias: 'Unnamed'
  required: false
  config: {},
  input: ''
  type:
    name: 'string'
    label: 'Unknown'
  valid: () ->
    !@required || @input
  getTransform: () ->
    _getValidationString @type, @config
  updateTransform: (rule) ->
    @config = _.omit @config, _.isNull
    @config = _.omit @config, _.isUndefined
    @config = _.omit @config, (v) -> v == ''
    if !@config?.advanced
      @transform = @getTransform()

baseRules =
  acres:
    alias: 'Acres'
    type: 'float'

  address:
    alias: 'Address'
    required: true
    input: {}
    group: 'general'
    type: 'address'
    valid: () ->
      @input.city && @input.state && (@input.zip || @input.zip9) &&
      ((@input.streetName && @input.streetNum) || @input.streetFull)

  baths_full:
    alias: 'Baths Full'
    type: 'integer'

  bedrooms:
    alias: 'Bedrooms'
    type: 'integer'

  days_on_market:
    alias: 'Days on Market'
    required: true
    input: []
    getTransform: () ->
      'validators.pickFirst({criteria: validators.integer()})'
    valid: () ->
      @input[0] || @input[1]

  fips_code:
    alias: 'FIPS code'
    required: true
    input: {}
    type: 'fips'
    valid: () ->
      @input.stateCode && @input.county

  hide_address:
    alias: 'Hide Address'
    type: 'boolean'

  hide_listing:
    alias: 'Hide Listing'
    type: 'boolean'

  parcel_id:
    alias: 'Parcel ID'
    required: true
    config:
      stripFormatting: true

  price:
    alias: 'Price'
    type: 'currency'
    required: true

  rm_property_id:
    alias: 'Property ID'
    required: true
    type: 'rm_property_id'
    input: {}

  sqft_finished:
    alias: 'Finished Sq Ft'
    type: 'integer'

  status:
    alias: 'Status'
    required: true
    getTransform: () ->
      _getValidationString 'map', map: @config.map ? {}, passUnmapped: true

  status_display:
    alias: 'Status Display'
    required: true
    group: 'general'
    getTransform: () ->
      _getValidationString 'map', map: @config.map ? {}, passUnmapped: true

  substatus:
    alias: 'Sub-Status'
    required: true
    getTransform: () ->
      _getValidationString 'map', map: @config.map ? {}, passUnmapped: true

  close_date:
    alias: 'Close Date'
    type: 'date'

  discontinued_date:
    alias: 'Discontinued Date'
    type: 'date'

  mls_uuid:
    alias: 'MLS Number'
    required: true

retsRules =
  Int:
    type:
      name: 'integer'
      label: 'Number (integer)'
    config:
      nullZero: true
  Decimal:
    type:
      name: 'float'
      label: 'Number (decimal)'
    config:
      nullZero: true
  Long:
    type:
      name: 'float'
      label: 'Number (decimal)'
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
    getTransform: () ->
      _getValidationString 'nullify', @config

_getValidationString = (type, vOptions) ->
  type = type.name || type
  vOptions = _.omit vOptions, 'advanced'
  vOptionsStr = if vOptions then JSON.stringify(vOptions) else ''
  "validators.#{type}(#{vOptionsStr})"

buildRule = (rule, defaults) ->
  _.defaultsDeep rule, defaults, ruleDefaults
  rule.updateTransform()

buildRetsRule = (rule) ->
  buildRule rule, retsRules[rule.DataType]
  if rule.type?.name == 'string'
    if rule.Interpretation == 'Lookup'
      rule.type.label = 'Restricted Text (single value)'
    else if rule.Interpretation == 'LookupMulti'
      rule.type.label = 'Restricted Text (multiple values)'
    else
      rule.type.label = 'User-Entered Text'
  rule

buildBaseRule = (rule) ->
  buildRule rule, baseRules[rule.output]

module.exports =
  baseRules: baseRules
  buildRetsRule: buildRetsRule
  buildBaseRule: buildBaseRule