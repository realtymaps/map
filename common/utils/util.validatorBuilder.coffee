_ = require 'lodash'

# Defaults for all rules
ruleDefaults =
  alias: 'Unnamed'
  required: false
  config: {},
  input: ''
  type:
    name: 'string'
    label: 'Unknown'

  # Check valid rule configuration (not data validation)
  valid: () ->
    !@required || @input

  getTransform: (globalOpts = {}) ->
    transformArr = []

    # Transforms that should precede type-specific logic
    if globalOpts.nullString
      transformArr.push name: 'nullify', options: value: String(globalOpts.nullString)

    # Primary transform
    options = _.pick @config, (v, k) -> ['advanced', 'DataType', 'nullZero', 'nullEmpty', 'nullNumber', 'nullString'].indexOf(k) == -1
    transformArr.push name: (@type?.name || @type), options: options

    # Transforms that should occur after type-specific logic
    if @config.nullZero
      transformArr.push name: 'nullify', options: value: 0
    if @config.nullEmpty
      transformArr.push name: 'nullify', options: value: ''
    if @config.nullNumber
      transformArr.push name: 'nullify', options: values: _.map @config.nullNumber, Number
    if @config.nullString
      transformArr.push name: 'nullify', options: values: _.map @config.nullString, String

    transformArr

  getTransformString: (globalOpts = {}) ->
    transforms = @getTransform(globalOpts)
    if !_.isArray transforms
      transforms = [ transforms ]
    strs = _.map transforms, @validatorString
    '[' + strs.join(',') + ']'

  validatorString: (validator) ->
    vOptionsStr = JSON.stringify(validator.options)
    "validators.#{validator.name}(#{vOptionsStr})"

# Base/filter rule definitions
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
      '[validators.pickFirst({criteria: validators.integer()})]'
    getTransformString: () ->
      '[validators.pickFirst({criteria: validators.integer()})]'
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
      name: 'map', options: map: @config.map ? {}, passUnmapped: true

  status_display:
    alias: 'Status Display'
    required: true
    group: 'general'
    getTransform: () ->
      name: 'map', options: map: @config.map ? {}, passUnmapped: true

  substatus:
    alias: 'Sub-Status'
    required: true
    getTransform: () ->
      name: 'map', options: map: @config.map ? {}, passUnmapped: true

  close_date:
    alias: 'Close Date'
    type: 'datetime'

  discontinued_date:
    alias: 'Discontinued Date'
    type: 'datetime'

  data_source_uuid:
    alias: 'MLS Number'
    required: true

# RETS/MLS rule defaults for each data type
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
      name: 'nullify', options: @config

_buildRule = (rule, defaults) ->
  _.defaultsDeep rule, defaults, ruleDefaults

buildRetsRule = (rule) ->
  _buildRule rule, retsRules[rule.config.DataType]
  if rule.type?.name == 'string'
    if rule.Interpretation == 'Lookup'
      rule.type.label = 'Restricted Text (single value)'
    else if rule.Interpretation == 'LookupMulti'
      rule.type.label = 'Restricted Text (multiple values)'
    else
      rule.type.label = 'User-Entered Text'
  rule

buildBaseRule = (rule) ->
  _buildRule rule, baseRules[rule.output]
  rule

module.exports =
  baseRules: baseRules
  buildRetsRule: buildRetsRule
  buildBaseRule: buildBaseRule