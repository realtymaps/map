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

  getOptions: () ->
    _.pick @config, (v, k) -> ['advanced', 'DataType', 'nullZero', 'nullEmpty', 'nullNumber', 'nullString'].indexOf(k) == -1

  getTransform: (globalOpts = {}) ->
    transformArr = []

    # Transforms that should precede type-specific logic
    if globalOpts.nullString
      transformArr.push name: 'nullify', options: value: String(globalOpts.nullString)

    # Primary transform
    transformArr.push name: (@type?.name || @type), options: @getOptions()

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
_allBaseRules =
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
    type: 'days_on_market'
    input: []
    valid: () ->
      @input[0] || @input[1]

  fips_code:
    alias: 'FIPS code'
    required: true
    input: {}
    type: 'fips'
    valid: () ->
      @input.stateCode && @input.county

  fips_code_field:
    alias: 'FIPS code'
    required: true
    type: 'fips'
    input: {}

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

  data_source_uuid_county:
    alias: 'County Number'
    required: true

  owner_name:
    alias: 'Owner 1'

  owner_name_2:
    alias: 'Owner 2'


# there is much crossover among baserules for different sources, so let's just pull what we need from the above list here for each source:
baseRules =
  'mls':
    'listing': _.pick _allBaseRules, [
      'acres',
      'address',
      'baths_full',
      'bedrooms',
      'days_on_market',
      'fips_code',
      'hide_address',
      'hide_listing',
      'parcel_id',
      'price',
      'rm_property_id',
      'sqft_finished',
      'status',
      'status_display',
      'substatus',
      'close_date',
      'discontinued_date',
      'data_source_uuid' ]
  'county':
    'tax': _.pick _allBaseRules, [
      'data_source_uuid_county',
      'rm_property_id',
      'fips_code_field',
      'parcel_id',
      'address',
      'price',
      'close_date',
      'bedrooms',
      'baths_full',
      'acres',
      'sqft_finished',
      'owner_name',
      'owner_name_2' ]
    'deed': {}

# RETS/MLS rule defaults for each data type
typeRules =
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
      name: 'nullify', options: @getOptions()

_buildRule = (rule, defaults) ->
  _.defaultsDeep rule, defaults, ruleDefaults

buildDataRule = (rule) ->
  _buildRule rule, typeRules[rule.config.DataType]
  if rule.type?.name == 'string'
    if rule.Interpretation == 'Lookup'
      rule.type.label = 'Restricted Text (single value)'
    else if rule.Interpretation == 'LookupMulti'
      rule.type.label = 'Restricted Text (multiple values)'
    else
      rule.type.label = 'User-Entered Text'
  rule

buildBaseRule = (dataSourceType, dataListType) ->
  (rule) ->
    _buildRule rule, baseRules[dataSourceType][dataListType][rule.output]
    rule

module.exports =
  baseRules: baseRules
  buildDataRule: buildDataRule
  buildBaseRule: buildBaseRule