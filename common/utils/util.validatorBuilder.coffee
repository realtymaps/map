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
_rules =
  common:
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

    parcel_id:
      alias: 'Parcel ID'
      required: true
      config:
        stripFormatting: true

    price:
      alias: 'Price'
      type: 'currency'
      required: true

    sqft_finished:
      alias: 'Finished Sq Ft'
      type: 'integer'

    close_date:
      alias: 'Close Date'
      type: 'datetime'

  mls:
    listing:
      rm_property_id:
        alias: 'Property ID'
        required: true
        type: 'rm_property_id'
        input: {}

      data_source_uuid:
        alias: 'MLS Number'
        required: true

      fips_code:
        alias: 'FIPS code'
        required: true
        input: {}
        type: 'fips'
        valid: () ->
          @input.stateCode && @input.county

      days_on_market:
        alias: 'Days on Market'
        required: true
        type: 'days_on_market'
        input: []
        valid: () ->
          @input[0] || @input[1]

      hide_address:
        alias: 'Hide Address'
        type: 'boolean'

      hide_listing:
        alias: 'Hide Listing'
        type: 'boolean'

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

      discontinued_date:
        alias: 'Discontinued Date'
        type: 'datetime'


  county:
    tax:
      rm_property_id:
        alias: 'Property ID'
        required: true
        type: 'rm_property_id'
        input: {}
        valid: () ->
          @input.fipsCode && @input.apnUnformatted && @input.apnSequence

      data_source_uuid:
        alias: 'County Number'
        required: true
        input: {}
        valid: () ->
          @input.batchid && @input.batchseq

      fips_code:
        alias: 'FIPS code'
        type: 'fips'
        required: true

      owner_name:
        alias: 'Owner 1'
        required: true
        input: {}
        valid: () ->
          @input.first && @input.last

      owner_name_2:
        alias: 'Owner 2'
        required: true
        input: {}
        valid: () ->
          @input.first && @input.last

    deed: {}

_noBase = ['deed']

getBaseRules = (dataSourceType, dataListType) ->
  if dataListType in _noBase
    return {}
  _.merge _.cloneDeep(_rules.common), _rules[dataSourceType][dataListType]

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
    _buildRule rule, getBaseRules(dataSourceType, dataListType)[rule.output]
    rule

module.exports =
  getBaseRules: getBaseRules
  buildDataRule: buildDataRule
  buildBaseRule: buildBaseRule