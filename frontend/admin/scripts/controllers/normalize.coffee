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
    if field.type?.name == 'string' and field.Interpretation?.indexOf('Lookup') == 0 and not field.lookups
      config = $scope.mlsData.current
      $scope.fieldLoading = rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.LookupName
      .then (lookups) ->
        field.lookups = lookups

  # Move rules between categories
  $scope.onDropCategory = (drag, drop, target) ->
    _.pull drag.collection, drag.model
    drop.collection.splice _.indexOf(drop.collection, target), 0, drag.model
    $scope.selectField(drag.model)
    $scope.$evalAsync()
    # todo: save

  # Map configuration options to transform JSON
  $scope.getTransform = () ->
    field = $scope.fieldData.current
    if field.DataType
      options =
        vOptions: _.pick field.config, (v) -> v?
        type: lookupType(field)?.name
      field.transform = validatorBuilder(options)
      $scope.saveRule field

  $scope.saveRule = _.debounce (rule) ->
    $scope.fieldLoading = rmapsNormalizeService.updateRule $scope.mlsData.current.id, rule
  , 2000

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
