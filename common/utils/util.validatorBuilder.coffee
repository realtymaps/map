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

      # `format` validator options
      'deliminate'
      'addDollarSign'
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

  # this groups up options that would cast new types, such as integer to string
  getFormatOptions: () ->
    _.pick(@config, [
      'deliminate'
      'addDollarSign'
    ])

  getTransform: (globalOpts = {}) ->
    transformArr = []

    # Transforms that should precede type-specific logic
    if globalOpts.nullString
      transformArr.push name: 'globalNullify', options: value: String(globalOpts.nullString)
    if @config.doLookup
      transformArr.push name: 'map', options: {unmapped: @config.unmapped||'pass', lookup: {lookupName: @config.LookupName, proxyName: @input, dataSourceId: @data_source_id, dataListType: @data_type}}
    if @config.nullEmptyArray
      transformArr.push name: 'nullify', options: value: ''  # same as @config.nullEmpty, but before primary transform

    # Primary transform
    transformArr.push name: @type?.name, options: @getOptions() # note: this forces correct cast-typing for incoming string values

    # Transforms that should occur after type-specific logic since previous steps change incoming strings to integers, floats, etc, as needed
    if @config.nullZero
      transformArr.push name: 'nullify', options: value: 0
    if @config.nullNumber
      transformArr.push name: 'nullify', options: values: _.map @config.nullNumber, Number
    if @config.nullEmpty
      transformArr.push name: 'nullify', options: value: ''
    if @config.nullBoolean?
      transformArr.push name: 'nullify', options: value: @config.nullBoolean
    if @config.nullString
      transformArr.push name: 'nullify', options: values: _.map @config.nullString, String
    if @config.mapping
      map = _.pick(@config.mapping, (val) -> val)  # filter out empty strings and other falsy mappings
      if Object.keys(map).length > 0
        transformArr.push name: 'map', options: {unmapped: @config.unmapped||'pass', map: map}

    # Transforms that should occur last, since they can change type (i.e. integer to string with dollar sign)
    formatOptions = @getFormatOptions()
    if !_.isEmpty formatOptions
      transformArr.push name: 'format', options: formatOptions

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

    price:
      alias: 'Price'
      type:
        name: 'currency'
        hasDecimal: true
      config:
        nullZero: true

    fips_code:
      alias: 'FIPS code'
      required: true
      input: {}
      type: name: 'fips'
      valid: () ->
        @input.fipsCode || (@input.stateCode && @input.county)

    address:
      alias: 'Property Address'
      input: {}
      type: name: 'address'
      valid: () ->
        @input.city && @input.state && (@input.zip || @input.zip9) &&
          ((@input.streetName && @input.streetNum) || @input.streetFull)

    close_date:
      alias: 'Close Date'
      type: name: 'datetime'

  mls:
    agent:
      license_number:
        alias: 'License Number'
        required: true
      full_name:
        alias: 'Full Name'
        required: true
        input: {}
        valid: () ->
          @input.first && @input.last || @input.full
        type: name: 'name'
      agent_status:
        alias: 'Status'
        required: true
      email:
        alias: 'Email'
      work_phone:
        alias: 'Work Phone'
      data_source_uuid:
        alias: 'Unique ID'
        required: true

    listing:
      creation_date:
        alias: 'Creation Date'
        type: name: 'datetime'

      data_source_uuid:
        alias: 'MLS Listing ID'
        required: true

      photo_id:
        alias: 'Photo ID'

      photo_last_mod_time:
        alias: 'Photo Last Mod Time'
        type: name: 'datetime'

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
        alias: 'Lot Area'
        type:
          name: 'lotArea'
          hasDecimal: true
        input: {}
        valid: () ->
          @input.acres? || @input.sqft?
        config:
          nullZero: true

      sqft_finished:
        alias: 'Finished Sq Ft'
        type: name: 'integer'

      days_on_market:
        alias: 'Days on Market'
        type: name: 'integer'

      days_on_market_cumulative:
        alias: 'Cumulative Days on Market'
        type: name: 'integer'

      days_on_market_filter:
        alias: 'Days on Market Filter'
        type: name: 'days_on_market'
        input: {}
        valid: () ->
          @input.creation_date? && @input.close_date?

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

      status_display:
        alias: 'Status Display'
        required: true

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
        config:
          unmapped: 'null'

      zoning:
        alias: 'Zoning'

      description:
        alias: 'Description'

      original_price:
        alias: 'Original Price'
        type:
          name: 'currency'
          hasDecimal: true
        config:
          nullZero: true

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

      recording_date:
        alias: 'Recording Date'
        type: name: 'datetime'

      property_type:
        alias: 'Property Type'
        config:
          unmapped: 'null'

    tax:
      close_date: null

      bedrooms:
        alias: 'Bedrooms'
        type: name: 'integer'

      baths:
        alias: 'Baths'
        type: name: 'bathrooms'
        input: {}
        config: {autodetect: true, implicit: total: 2}
        valid: () ->
          @input.half? && @input.full? || @input.total?

      acres:
        alias: 'Lot Area'
        type:
          name: 'lotArea'
          hasDecimal: true
        input: {}
        valid: () ->
          @input.acres? || @input.sqft?
        config:
          nullZero: true

      sqft_finished:
        alias: 'Finished Sq Ft'
        type: name: 'integer'

      year_built:
        alias: 'Year Built or Age'
        type: name: 'yearOrAge'
        input: {}
        valid: () ->
          @input.year || @input.age

      zoning:
        alias: 'Zoning'

      legal_unit_number:
        alias: 'Legal Unit Number'

      appraised_value:
        alias: 'Appraised Value'
        type:
          name: 'currency'
          hasDecimal: true
        config:
          nullZero: true

    deed:
      legal_unit_number:
        alias: 'Legal Unit Number'

      seller_name:
        alias: 'Seller 1'
        required: true
        input: {}
        valid: () ->
          @input.first && @input.last || @input.full
        type: name: 'name'

      seller_name_2:
        alias: 'Seller 2'
        input: {}
        valid: () ->
          @input.first && @input.last || @input.full
        type: name: 'name'

      document_type:
        alias: 'Document Type'

    mortgage:
      price: null
      property_type: null
      owner_name: null
      owner_name_2: null
      owner_address: null

      amount:
        alias: 'Loan Amount'
        valid: () ->
          @input.amount && @input.scale
        input: {}
        type: name: 'amount'

      lender:
        alias: 'Lender'

      term:
        alias: 'Loan Term'
        type: name: 'yearsOrMonths'
        input: {}

      financing_type:
        alias: 'Financing Type'

      loan_type:
        alias: 'Loan Type'


# RETS/MLS rule defaults for each data type
typeRules =
  Int:
    type:
      name: 'integer'
      label: 'Number (integer)'
    config:
      nullZero: true
  Tiny:
    type:
      name: 'integer'
      label: 'Number (integer)'
    config:
      nullZero: true
  Small:
    type:
      name: 'integer'
      label: 'Number (integer)'
    config:
      nullZero: true
  Decimal:
    type:
      name: 'float'
      label: 'Number (decimal)'
      hasDecimal: true
    config:
      nullZero: true
  Long:
    type:
      name: 'float'
      label: 'Number (integer)'
    config:
      nullZero: true
  Character:
    type:
      name: 'string'
    config:
      nullEmpty: true
      trim: true
  DateTime:
    type:
      name: 'datetime'
      label: 'Date and Time'
  Date:
    type:
      name: 'datetime'
      label: 'Date'
  Time:
    type:
      name: 'datetime'
      label: 'Time'
  Boolean:
    type:
      name: 'boolean'
      label: 'Yes/No'
    config:
      nullBoolean: false
      truthyOutput: 'yes'
      falsyOutput: 'no'
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

_classifyRule = (rule) ->
  lcName = rule.input.toLowerCase()

  if rule.type?.name == 'string' && rule.config.Interpretation == 'Lookup'
    return 'Lookup'

  if rule.type?.name == 'string' && rule.config.Interpretation == 'LookupMulti'
    return 'LookupMulti'

  currencyWordRegex = /\bprice\b|\bamount\b|\bfee\b|\$/ #['price', 'amount', 'fee', '$']
  currencyTypes = ['float', 'integer']
  if rule.type?.name in currencyTypes && (rule.config.Interpretation == 'Currency' || currencyWordRegex.test(lcName))
    return 'Currency'

  if rule.type?.name == 'datetime' || rule.config.DataType == 'DateTime'
    return 'DateTime'


getBaseRules = (dataSourceType, dataListType) ->
  p1 = _.cloneDeep(_rules[dataSourceType][dataListType])
  p2 = _.cloneDeep(_rules[dataSourceType].common)
  p3 = _.cloneDeep(_rules.common)
  builtBaseRules = _.defaultsDeep(p1, p2, p3)
  return _(builtBaseRules).mapValues((val) -> _.defaultsDeep(val, baseTypeRules[val?.type?.name ? 'string'])).omit((val) -> !val?).value()
getBaseRules = _.memoize(getBaseRules, (dataSourceType, dataListType) -> "#{dataSourceType}__#{dataListType}")

getAgentRules = () ->
  p1 = _.cloneDeep(_rules['mls']['agent'])
  return _(p1).mapValues((val) -> _.defaultsDeep(val, baseTypeRules[val?.type?.name ? 'string'])).omit((val) -> !val?).value()

buildDataRule = (rule) ->
  _buildRule rule, typeRules[rule.config.DataType]

  # We want to support a reasonable formatting for non-base data fields so that they look good, even though there are hundreds of fields to
  #   configure. Their names and types are generally stochastic, but we can deduce, classify, then configure given certain classification rules.
  #
  #   Exceptions can be adjusted in the admin UI after defaults have been applied to the rule.
  #
  #   These cannot exist as default type config parameters in the `typeRules` above since base fields use `typeRules` also, and config options that
  #   change the primitave type (such as from datetime to string) should only occur for nonbase (regular data) fields
  classified = _classifyRule(rule)
  switch classified
    when "Lookup"
      rule.type.label = 'Restricted Text (single value)'
      if rule.data_source_type == 'county'
        rule.config.doLookup ?= true

    when "LookupMulti"
      rule.type.label = 'Restricted Text (multiple values)'
      rule.type.name = 'array'
      if rule.data_source_type == 'county'
        rule.config.doLookup ?= true
      rule.config.split ?= ','
      rule.config.nullEmptyArray ?= true
      rule.config.nullEmpty = false

    when "Currency"
      rule.config.deliminate ?= true
      rule.config.addDollarSign ?= true

    when "DateTime"
      rule.config.outputFormat ?= 'MMMM Do, YYYY'

    else
      rule.type.label = 'User-Entered Text'

  rule

buildBaseRule = (dataSourceType, dataListType) ->
  (rule) ->
    _buildRule rule, getBaseRules(dataSourceType, dataListType)[rule.output]
    rule

buildAgentRule = () ->
  (rule) ->
    _buildRule rule, getAgentRules()[rule.output]
    rule

module.exports = {
  getBaseRules
  getAgentRules
  buildDataRule
  buildBaseRule
  buildAgentRule
}
