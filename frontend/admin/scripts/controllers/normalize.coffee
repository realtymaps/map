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

  # Handles adding rules to each list
  addRule = (rule, list) ->
    _.extend rule,
      ordering: parseInt(rule.ordering||0, 10)
      config: rule.config || {}
      list: list
    if rule.list == 'base'
      validateBase(rule)
    category = $scope.categories[list]
    idx = _.sortedIndex(category, rule, 'ordering')
    category.splice idx, 0, allRules[rule.output] = rule

  # Handles parsing existing rules for display
  parseRules = (rules) ->
    _.forEach rules, (rule) ->
      addRule rule, rule.list

  # Handles parsing RETS fields for display
  parseFields = (fields) ->
    _.forEach fields, (field) ->
      _.extend field,
        output: field.LongName
      rule = allRules[field.output]
      if not rule
        addRule field, 'unassigned'
      else
        _.extend allRules[field.output], _.pick(field, ['DataType', 'Interpretation', 'LookupName'])

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
    field.type = validatorBuilder.lookupType(field)
    $scope.fieldData.current = field
    $scope.loadLookups(if field.list == 'base' then allRules[field.input] else field)

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
    rmapsNormalizeService.moveRule $scope.mlsData.current.id,
      drag.model,
      _.find($scope.targetCategories, (c) -> c.items == drag.collection),
      _.find($scope.targetCategories, (c) -> c.items == drop.collection),
      _.indexOf(drop.collection, target)

    $scope.selectField(drag.model)
    $scope.$evalAsync()

  $scope.onDropBaseInput = (drag, drop, target) ->
    field = $scope.fieldData.current
    field.input[drop.collection] = drag.model.output
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
    field.input = drag.model.output
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
    if field.list == 'address'
      field.valid = input.city && input.state && (input.zip || input.zip9) &&
       ((input.streetName && input.streetNum) || input.streetFull)
    else
      field.valid = field.input?

  # User input triggers this
  $scope.getTransform = _.debounce (() -> setTransform($scope.fieldData.current)), 2000

  # Map configuration options to transform JSON
  setTransform = (field) ->
    field.transform = validatorBuilder.getTransform(field)
    saveRule field

  saveRule = (rule) ->
    $scope.fieldLoading = rmapsNormalizeService.updateRule $scope.mlsData.current.id, rule
]
