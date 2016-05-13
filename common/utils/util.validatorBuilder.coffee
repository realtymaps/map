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
    options = _.omit(@config, [
      'advanced'
      'alias'
      'DataType'
      'LookupName'
      'Interpretation'
      'nullZero'
      'nullEmpty'
      'nullEmptyArray'
      'nullNumber'
      'nullString'
      'nullBoolean'
      'doLookup'
      'mapping'
      'truthiness'
    ])
    if @config.truthiness && Object.keys(@config.truthiness).length > 0
      options.truthy = []
      options.falsy = []
      for value, truthiness of @config.truthiness
        if truthiness
          options.truthy.push(value)
        else
          options.falsy.push(value)
    options

  getTransform: (globalOpts = {}) ->
    transformArr = []

    # Transforms that should precede type-specific logic
    if globalOpts.nullString
      transformArr.push name: 'nullify', options: value: String(globalOpts.nullString)
    if @config.doLookup
      transformArr.push name: 'map', options: {passUnmapped: true, lookup: {lookupName: @config.LookupName, dataSourceId: @data_source_id, dataListType: @data_type}}
    if @config.nullEmptyArray
      transformArr.push name: 'nullify', options: value: ''  # same as @config.nullEmpty, but before primary transform

    # Primary transform
    transformArr.push name: @type?.name, options: @getOptions()

    # Transforms that should occur after type-specific logic
    if @config.nullZero
      transformArr.push name: 'nullify', options: value: 0
    if @config.nullEmpty
      transformArr.push name: 'nullify', options: value: ''
    if @config.nullBoolean?
      transformArr.push name: 'nullify', options: value: @config.nullBoolean
    if @config.nullNumber
      transformArr.push name: 'nullify', options: values: _.map @config.nullNumber, Number
    if @config.nullString
      transformArr.push name: 'nullify', options: values: _.map @config.nullString, String
    if @config.mapping
      map = _.pick(@config.mapping, (val) -> val)  # filter out empty strings and other falsy mappings
      if Object.keys(map).length > 0
        transformArr.push name: 'map', options: {passUnmapped: true, map: map}

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

    fips_code:
      alias: 'FIPS code'
      required: true
      input: {}
      type: name: 'fips'
      valid: () ->
        @input.fipsCode || (@input.stateCode && @input.county)

    address:
      alias: 'Address'
      input: {}
      type: name: 'address'
      valid: () ->
        @input.city && @input.state && (@input.zip || @input.zip9) &&
          ((@input.streetName && @input.streetNum) || @input.streetFull)

  mls:
    listing:
      data_source_uuid:
        alias: 'MLS Number'
        required: true

      photo_id:
        alias: 'Photo ID'

      photo_count:
        alias: 'Photo Count'
        type: name: 'integer'

      photo_last_mod_time:
        alias: 'Photo Last Mod Time'
        type: name: 'datetime'

      address:
        group: 'general'

      bedrooms:
        alias: 'Bedrooms'
        type: name: 'integer'

      baths:
        alias: 'Baths'
        type: name: 'bathrooms'
        input: {}
        valid: () ->
          @input.half? && @input.full? || @input.total?

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
        config:
          nullBoolean: null

      hide_listing:
        alias: 'Hide Listing'
        type: name: 'boolean'
        config:
          nullBoolean: null

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
        alias: 'Year Built or Age'
        type: name: 'yearOrAge'
        input: {}
        valid: () ->
          @input.year || @input.age

      property_type:
        alias: 'Property Type'
        getTransform: () ->
          name: 'map', options: map: @config.map ? {}, passUnmapped: true


  county:
    common:
      data_source_uuid:
        alias: 'Data Source UUID'
        required: true
        input: {}
        valid: () ->
          @input.batchid
        type: name: 'data_source_uuid'

      owner_name:
        alias: 'Owner 1'
        required: true
        input: {}
        valid: () ->
          @input.first && @input.last || @input.full
        type: name: 'name'

      owner_name_2:
        alias: 'Owner 2'
        required: true
        input: {}
        valid: () ->
          @input.first && @input.last || @input.full
        type: name: 'name'

      owner_address:
        alias: "Owner's Address"
        input: {}
        type: name: 'address'
        valid: () ->
          @input.city && @input.state && (@input.zip || @input.zip9) &&
            ((@input.streetName && @input.streetNum) || @input.streetFull)


    tax:
      address:
        group: 'general'

      bedrooms:
        alias: 'Bedrooms'
        type: name: 'integer'

      baths:
        alias: 'Baths'
        type: name: 'bathrooms'
        input: {}
        valid: () ->
          @input.half? && @input.full? || @input.total?

      acres:
        alias: 'Acres'
        type: name: 'float'

      sqft_finished:
        alias: 'Finished Sq Ft'
        type: name: 'integer'

      owner_name:
        group: 'owner'

      owner_name_2:
        group: 'owner'

      owner_address:
        group: 'owner'

      year_built:
        alias: 'Year Built or Age'
        type: name: 'yearOrAge'
        input: {}
        valid: () ->
          @input.year || @input.age

    deed:
      address:
        group: 'deed'

      owner_name:
        group: 'owner'

      owner_name_2:
        group: 'owner'

      owner_address:
        group: 'owner'

      property_type:
        alias: 'Property Type'
        getTransform: () ->
          name: 'map', options: map: @config.map ? {}, passUnmapped: true

      zoning:
        alias: 'Zoning'
        getTransform: () ->
          name: 'map', options: map: @config.map ? {}, passUnmapped: true

    mortgage:
      address:
        group: 'mortgage'

      owner_name:
        group: 'mortgage'

      owner_name_2:
        group: 'mortgage'

      owner_address:
        group: 'mortgage'


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
    config:
      nullBoolean: false
    valid: () ->
      if !@lookups
        return true
      # if this field has a lookup, you must mark something for all lookups, and must have both truthy and falsy values
      if !@config.truthiness
        return false
      foundTruthy = false
      foundFalsy = false
      for lookup in @lookups
        if !@config.truthiness[lookup.LongValue]?
          return false
        if @config.truthiness[lookup.LongValue]
          foundTruthy = true
        if !@config.truthiness[lookup.LongValue]
          foundFalsy = true
      return foundTruthy && foundFalsy

# this is a remapping of the above RETS type rules, but indexed on validation types rather than RETS types
baseTypeRules =
  boolean: _.omit(typeRules.Boolean, 'type')
  datetime: _.omit(typeRules.DateTime, 'type')
  string: _.omit(typeRules.Character, 'type')
  float: _.omit(typeRules.Decimal, 'type')
  integer: _.omit(typeRules.Int, 'type')

_buildRule = (rule, defaults) ->
  _.defaultsDeep rule, _.cloneDeep(defaults), _.cloneDeep(ruleDefaults)

getBaseRules = (dataSourceType, dataListType) ->
  p1 = _.cloneDeep(_rules[dataSourceType][dataListType])
  p2 = _.cloneDeep(_rules[dataSourceType].common)
  p3 = _.cloneDeep(_rules.common)
  builtBaseRules = _.defaultsDeep(p1, p2, p3)
  return _.mapValues builtBaseRules, (val) -> _.defaultsDeep(val, baseTypeRules[val.type?.name ? 'string'])
getBaseRules = _.memoize(getBaseRules, (dataSourceType, dataListType) -> "#{dataSourceType}__#{dataListType}")

buildDataRule = (rule) ->
  _buildRule rule, typeRules[rule.config.DataType]
  if rule.type?.name == 'string'
    if rule.config.Interpretation == 'Lookup'
      rule.type.label = 'Restricted Text (single value)'
      if rule.data_source_type == 'county'
        rule.config.doLookup ?= true
    else if rule.config.Interpretation == 'LookupMulti'
      rule.type.label = 'Restricted Text (multiple values)'
      rule.type.name = 'array'
      rule.config.split = ','
      rule.config.nullEmptyArray = true
      rule.config.nullEmpty = false
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
