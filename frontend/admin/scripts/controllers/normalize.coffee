app = require '../app.coffee'
_ = require 'lodash'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
require '../directives/dragdrop.coffee'
require '../directives/listinput.coffee'
require '../factories/validatorBuilder.coffee'

app.controller 'rmapsNormalizeCtrl', [ '$scope', '$rootScope', '$state', 'rmapsMlsService', 'rmapsNormalizeService', 'validatorBuilder', 'rmapsevents', ($scope, $rootScope, $state, rmapsMlsService, rmapsNormalizeService, validatorBuilder, rmapsevents) ->
  $scope.$state = $state

  $scope.mlsData =
    current: null

  $scope.fieldData =
    current: null

  $scope.transformOptions =
    'Uppercase': 'forceUpperCase'
    'Lowercase': 'forceLowerCase'
    'Init Caps': 'forceInitCaps'

  $scope.addressOptions = _.map
    'Street Number': 'streetNum'
    'Street Name': 'streetName'
    'City': 'city'
    'State or Province': 'state'
    'Postal Code': 'zip'
    'Postal Code + 4': 'zip9'
    'Street Dir Prefix': 'streetDirPrefix'
    'Street Dir Suffix': 'streetDirSuffix'
    'Street Number Modifier': 'streetNumModifier'
    'Full Address': 'streetFull',
    (key, label) ->
      label: label
      key: key

  $scope.statusOptions = [
    'for sale',
    'pending',
    'not for sale',
    'sold'
  ]

  $scope.subStatusOptions = [
    'for sale',
    'pending',
    'pending-contingent',
    'sold',
    'terminated',
    'expired',
    'withdrawn'
  ]

  $scope.categories = {}
  $scope.targetCategories = _.map
    base: 'Base'
    unassigned: 'Unassigned'
    hidden: 'Hidden'
    general: 'General'
    details: 'Details'
    listing: 'Listing'
    building: 'Building'
    lot: 'Lot'
    location: 'Location & Schools'
    dimensions: 'Room Dimensions'
    restrictions: 'Taxes, Fees, and Restrictions'
    contacts: 'Listing Contacts (realtor only)'
    realtor: 'Listing Details (realtor only)'
    sale: 'Sale Details (realtor only)',
    (label, list) ->
      label: label
      list: list
      items: $scope.categories[list] = []

  # Load MLS list
  rmapsMlsService.getConfigs()
  .then (configs) ->
    $scope.mlsConfigs = configs

  allRules = {}

  # Handles parsing existing rules for display
  parseRules = (rules) ->

    addRule = (rule, list) ->
      _.extend rule,
        label: rule.output
        ordering: parseInt(rule.ordering, 10)
      if rule.list == 'base'
        rule.baseName = rule.output
        validateBase(rule)
      list.splice _.sortedIndex(list, rule, 'ordering'), 0, allRules[rule.output] = rule

    addComplexRule = (rule, keys) ->
      _.forEach keys, (key) ->
        if allRules[key]
          allRules[key].assigned = true
        else
          $scope.categories.unassigned.push(
            allRules[key] =
            assigned: true
            label: rule.key
          )
      addRule _.extend(rule, composite: true), $scope.categories[rule.list]

    # Regular rules
    _.forEach _.where(rules, (r) -> !r.input?), (rule) ->
      if not allRules[rule.output]
        addRule rule, $scope.categories[rule.list]
      else
        $rootScope.$emit rmapsevents.alert.spawn, msg: "Duplicate rule for #{rule.output}!"

    # Complex rules
    _.forEach rules, (rule) ->
      if _.isString rule.input
        addComplexRule(rule, [rule.input])
      else if _.isArray rule.input
        addComplexRule(rule, rule.input)
      else if _.isPlainObject rule.input
        addComplexRule(rule, _.values(rule.input))

  # Handles parsing RETS fields for display
  parseFields = (fields) ->
    _.forEach fields, (c) ->
      _.extend c, label: c.LongName
      rule = allRules[c.LongName]
      if rule and not rule.LongName
        _.extend rule, _.pick(c, ['label', 'DataType', 'Interpretation', 'LookupName'])
      else
        $scope.categories.unassigned.push c # todo load defaults

  # Load saved MLS config and RETS fields
  $scope.selectMls = () ->
    config = $scope.mlsData.current
    $scope.mlsLoading =
      rmapsNormalizeService.getRules(config.id)
      .then (rules) ->
        parseRules(rules)
        rmapsMlsService.getColumnList(config.id, config.main_property_data.db, config.main_property_data.table)
      .then (fields) ->
        parseFields(fields)

  # Show field options
  $scope.selectField = (field) ->
    $scope.showProperties = true
    field.type = lookupType(field)
    if not field.config
      field.config = {}
    $scope.fieldData.current = field
    $scope.loadLookups(if field.baseName then allRules[field.input] else field)

  $scope.loadLookups = (field) ->
    if field?.lookups
      $scope.fieldData.current.lookups = field.lookups
    else if field && !field.lookups && field.LookupName
      config = $scope.mlsData.current
      $scope.fieldLoading = rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.LookupName
      .then (lookups) ->
        $scope.fieldData.current.lookups = field.lookups = lookups
        $scope.$evalAsync()

  # Move rules between categories
  $scope.onDropCategory = (drag, drop, target) ->
    _.pull drag.collection, drag.model
    drop.collection.splice _.indexOf(drop.collection, target), 0, drag.model
    $scope.selectField(drag.model)
    $scope.$evalAsync()

  $scope.onDropBaseInput = (drag, drop, target) ->
    field = $scope.fieldData.current
    field.input[drop.collection] = drag.model.label
    updateBase(field)

  # Remove base field input
  $scope.removeBaseInput = (key) ->
    field = $scope.fieldData.current
    delete field.input[key]
    delete field.lookups
    delete field.config.choices
    updateBase(field)

  # Move rules to base field config
  $scope.onDropBase = (drag, drop, target) ->
    field = $scope.fieldData.current
    field.input = drag.model.label
    $scope.loadLookups(drag.model)
    updateBase(field)

  # Remove base field input
  $scope.removeBase = () ->
    field = $scope.fieldData.current
    field.input = null
    delete field.lookups
    delete field.config.choices
    updateBase(field)

  updateBase = (field) ->
    setTransform(field)
    validateBase(field)

  validateBase = (field) ->
    input = field.input
    if field.baseName == 'address'
      field.valid = input.city && input.state && (input.zip || input.zip9) &&
       ((input.streetName && input.streetNum) || input.streetFull)
    else
      field.valid = field.input?

  # User input triggers this
  $scope.getTransform = _.debounce (() -> setTransform($scope.fieldData.current)), 2000

  # Map configuration options to transform JSON
  setTransform = (field) ->
    field.transform = validatorBuilder
      vOptions: _.pick field.config, (v) -> v?
      type: lookupType(field)?.name
      baseName: field.baseName
    saveRule field

  saveRule = (rule) ->
    $scope.fieldLoading = rmapsNormalizeService.updateRule $scope.mlsData.current.id, rule

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

]
