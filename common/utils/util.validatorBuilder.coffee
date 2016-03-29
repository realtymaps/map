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

  # this excludes certain config fields from going into the transform (the ones that are handled manually in getTransform)
  getOptions: () ->
    _.pick @config, (v, k) -> ['advanced', 'alias', 'DataType', 'nullZero', 'nullEmpty', 'nullNumber', 'nullString'].indexOf(k) == -1

  getTransform: (globalOpts = {}) ->
    transformArr = []

    # Transforms that should precede type-specific logic
    if globalOpts.nullString
      transformArr.push name: 'nullify', options: value: String(globalOpts.nullString)

    # Primary transform
    transformArr.push name: @type?.name, options: @getOptions()

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
    rm_property_id:
      alias: 'Property ID'
      required: true
      type: name: 'rm_property_id'
      input: {}
      valid: () ->
        @input.apn && (@input.fipsCode || (@input.stateCode && @input.county))

    parcel_id:
      alias: 'Parcel ID'
      required: true
      config:
        stripFormatting: true

    price:
      alias: 'Price'
      type: name: 'currency'
      config:
        nullZero: true

    close_date:
      alias: 'Close Date'
      type: name: 'datetime'

  mls:
    listing:
      data_source_uuid:
        alias: 'MLS Number'
        required: true

      photo_id:
        alias: 'Photo ID'
        required: false

      photo_count:
        alias: 'Photo Count'
        required: false

      address:
        alias: 'Address'
        input: {}
        group: 'general'
        type: name: 'address'
        valid: () ->
          @input.city && @input.state && (@input.zip || @input.zip9) &&
            ((@input.streetName && @input.streetNum) || @input.streetFull)

      fips_code:
        alias: 'FIPS code'
        required: true
        input: {}
        type: name: 'fips'
        valid: () ->
          @input.stateCode && @input.county

      bedrooms:
        alias: 'Bedrooms'
        type: name: 'integer'

      baths_full:
        alias: 'Baths Full'
        type: name: 'integer'

      acres:
        alias: 'Acres'
        type: name: 'float'

      sqft_finished:
        alias: 'Finished Sq Ft'
        type: name: 'integer'

      days_on_market:
        alias: 'Days on Market'
        required: true
        type: name: 'days_on_market'
        input: []
        valid: () ->
          @input[0] || @input[1]

      hide_address:
        alias: 'Hide Address'
        type: name: 'boolean'

      hide_listing:
        alias: 'Hide Listing'
        type: name: 'boolean'

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
        type: name: 'datetime'

      year_built:
        alias: 'Year Built'
        type: name: 'integer'

      property_type:
        alias: 'Property Type'
        config:
          transformString: 'forceInitCaps'


  county:
    tax:
      data_source_uuid:
        alias: 'Data Source UUID'
        required: true
        input: {}
        valid: () ->
          @input.batchid
        type: name: 'data_source_uuid'

      address:
        alias: 'Address'
        input: {}
        group: 'general'
        type: name: 'address'
        valid: () ->
          @input.city && @input.state && (@input.zip || @input.zip9) &&
            ((@input.streetName && @input.streetNum) || @input.streetFull)

      fips_code:
        alias: 'FIPS code'
        type: name: 'fips'
        required: true

      bedrooms:
        alias: 'Bedrooms'
        type: name: 'integer'

      baths_full:
        alias: 'Baths Full'
        type: name: 'integer'

      acres:
        alias: 'Acres'
        type: name: 'float'

      sqft_finished:
        alias: 'Finished Sq Ft'
        type: name: 'integer'

      owner_name:
        alias: 'Owner 1'
        required: true
        input: {}
        group: 'owner'
        valid: () ->
          @input.first && @input.last || @input.full
        type: name: 'name'

      owner_name_2:
        alias: 'Owner 2'
        required: true
        input: {}
        group: 'owner'
        valid: () ->
          @input.first && @input.last || @input.full
        type: name: 'name'

      owner_address:
        alias: "Owner's Address"
        input: {}
        group: 'owner'
        type: name: 'address'
        valid: () ->
          @input.city && @input.state && (@input.zip || @input.zip9) &&
            ((@input.streetName && @input.streetNum) || @input.streetFull)

      year_built:
        alias: 'Year Built'
        type: name: 'integer'

      property_type:
        alias: 'Property Type'
        config:
          transformString: 'forceInitCaps'

    deed:
      data_source_uuid:
        alias: 'Data Source UUID'
        required: true
        input: {}
        valid: () ->
          @input.batchid
        type: name: 'data_source_uuid'

      fips_code:
        alias: 'FIPS code'
        type: name: 'fips'
        required: true

      address:
        alias: 'Address'
        input: {}
        group: 'deed'
        type: name: 'address'
        valid: () ->
          @input.city && @input.state && (@input.zip || @input.zip9) &&
            ((@input.streetName && @input.streetNum) || @input.streetFull)

      owner_name:
        alias: 'Owner 1'
        required: true
        input: {}
        group: 'owner'
        valid: () ->
          @input.first && @input.last
        type: name: 'name'

      owner_name_2:
        alias: 'Owner 2'
        required: true
        input: {}
        group: 'owner'
        valid: () ->
          @input.first && @input.last
        type: name: 'name'

      owner_address:
        alias: "Owner's Address"
        input: {}
        group: 'owner'
        type: name: 'address'
        valid: () ->
          @input.city && @input.state && (@input.zip || @input.zip9) &&
            ((@input.streetName && @input.streetNum) || @input.streetFull)

    mortgage:
      data_source_uuid:
        alias: 'Data Source UUID'
        type: name: 'data_source_uuid'
        required: true
        input: {}
        valid: () ->
          @input.batchid

      fips_code:
        alias: 'FIPS code'
        type: name: 'fips'
        required: true

      address:
        alias: 'Address'
        input: {}
        group: 'mortgage'
        type: name: 'address'
        valid: () ->
          @input.city && @input.state && (@input.zip || @input.zip9) &&
            ((@input.streetName && @input.streetNum) || @input.streetFull)

      owner_name:
        alias: 'Owner 1'
        required: true
        input: {}
        group: 'mortgage'
        valid: () ->
          @input.first && @input.last
        type: name: 'name'

      owner_name_2:
        alias: 'Owner 2'
        required: true
        input: {}
        group: 'mortgage'
        valid: () ->
          @input.first && @input.last
        type: name: 'name'

      owner_address:
        alias: "Owner's Address"
        input: {}
        group: 'mortgage'
        type: name: 'address'
        valid: () ->
          @input.city && @input.state && (@input.zip || @input.zip9) &&
            ((@input.streetName && @input.streetNum) || @input.streetFull)

# no lists currently have no base filters, but deed used to, so
# we'll keep this around just in case something comes along that needs this)
_noBase = []

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
  _.defaultsDeep rule, _.cloneDeep(defaults), _.cloneDeep(ruleDefaults)

getBaseRules = (dataSourceType, dataListType) ->
  if dataListType in _noBase
    return {}
  _.merge _.cloneDeep(_rules.common), _.cloneDeep(_rules[dataSourceType][dataListType])

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
