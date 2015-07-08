app = require '../app.coffee'
_ = require 'lodash'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
require '../directives/dragdrop.coffee'
require '../directives/listinput.coffee'
require '../factories/validatorBuilder.coffee'

app.controller 'rmapsRulesCtrl',
($scope, $rootScope, $state, rmapsMlsService, rmapsNormalizeService, validatorBuilder, rmapsevents, rmapsParcelEnums) ->

  console.log 'rmapsRulesCtrl'
  vm = this

  vm.mlsData =
    current: $scope.selectedMls

  vm.fieldData = null

  vm.transformOptions =
    'Uppercase': 'forceUpperCase'
    'Lowercase': 'forceLowerCase'
    'Init Caps': 'forceInitCaps'

  vm.addressOptions = _.map rmapsParcelEnums.address, (label, key) ->
    label: label
    key: key

  vm.statusOptions = _.values rmapsParcelEnums.status

  vm.subStatusOptions = _.values rmapsParcelEnums.subStatus

  vm.baseRules = validatorBuilder.baseRules

  vm.categories = {}
  vm.targetCategories = _.map rmapsParcelEnums.categories, (label, list) ->
    label: label
    list: list
    items: vm.categories[list] = []

  allRules = {}

  # Handles adding rules to categories
  addRule = (rule, list) ->
    category = vm.categories[list]
    _.extend rule,
      ordering: rule.ordering ? category.length
      config: rule.config || {}
      list: list
    idx = _.sortedIndex(category, rule, 'ordering')
    category.splice idx, 0, allRules[rule.output] = rule

  # Handles adding base rules
  addBaseRule = (rule) ->
    validatorBuilder.validateBase rule
    addRule rule, 'base'

  # Handles parsing existing rules for display
  parseRules = (rules) ->
    # Load existing rules first
    _.forEach rules, (rule) ->
      if rule.list == 'base'
        addBaseRule rule
      else
        addRule rule, rule.list
    # Create base rules that don't exist yet
    _.forEach vm.baseRules, (rule, output) ->
      if !allRules[output]
        rule.output = output
        addBaseRule rule

    # Save base rules
    vm.baseLoading = rmapsNormalizeService.createListRules vm.mlsData.current.id, 'base', vm.categories.base

  # Handles parsing RETS fields for display
  parseFields = (fields) ->
    _.forEach fields, (field) ->
      rule = allRules[field.LongName]
      if rule
        _.extend rule, _.pick(field, ['DataType', 'Interpretation', 'LookupName'])
      else
        rule = field
        rule.output = rule.LongName
        addRule rule, 'unassigned'
      rule.type = validatorBuilder.lookupType(field)
      true

    _.forEach vm.categories.base, (rule) -> updateAssigned(rule)

  # Show field options
  vm.selectField = (field) ->
    vm.showProperties = true
    vm.fieldData = field
    vm.loadLookups(if field.list == 'base' then allRules[field.input] else field)

  vm.loadLookups = (field) ->
    if field?.lookups
      vm.fieldData.lookups = field.lookups
    else if field && !field.lookups && field.LookupName
      config = vm.mlsData.current
      vm.mlsLoading = rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.LookupName
      .then (lookups) ->
        vm.fieldData.lookups = field.lookups = lookups
        vm.$evalAsync()

  # Move rules between categories
  vm.onDropCategory = (drag, drop, target) ->
    if drag.model.unselectable
      return
    from = _.find(vm.targetCategories, (c) -> c.items == drag.collection)
    to = _.find(vm.targetCategories, (c) -> c.items == drop.collection)
    idx = _.indexOf(drop.collection, target)
    if to.list != 'unassigned'
      vm.fieldData.category = to
    from.loading = to.loading = rmapsNormalizeService.moveRule(
      vm.mlsData.current.id,
      drag.model,
      from,
      to,
      if idx != -1 then idx else 0
    ).then () ->
      vm.selectField(drag.model)
      vm.$evalAsync()

  vm.onDropBaseInput = (drag, drop, target) ->
    field = vm.fieldData
    key = drop.collection
    removed = field.input[key]
    field.input[key] = drag.model.output
    updateAssigned(field)
    updateBase(field, removed)

  # Remove base field input
  vm.removeBaseInput = (key) ->
    field = vm.fieldData
    removed = field.input[key]
    delete field.input[key]
    delete field.lookups
    delete field.config.choices
    updateBase(field, removed)

  # Move rules to base field config
  vm.onDropBase = (drag, drop, target) ->
    field = vm.fieldData
    removed = field.input
    field.input = drag.model.output
    vm.loadLookups(drag.model)
    updateBase(field, removed)

  # Remove base field input
  vm.removeBase = () ->
    field = vm.fieldData
    removed = field.input
    field.input = null
    delete field.lookups
    delete field.config.choices
    updateBase(field, removed)

  updateBase = (field, removed) ->
    validatorBuilder.validateBase(field)
    field.inputString = JSON.stringify(field.input) # for display
    updateAssigned(field, removed)
    saveRule()

  updateAssigned = (rule, removed) ->
    if vm.baseRules[rule.output].group
      delete allRules[removed]?.assigned
      if _.isString rule.input
        allRules[rule.input]?.assigned = true
      else _.forEach rule.input, (input) ->
        allRules[input]?.assigned = true

  # User input triggers this
  vm.updateRule = () ->
    field = vm.fieldData
    field.transform = validatorBuilder.getTransform field
    vm.saveRuleDebounced()

  saveRule = () ->
    vm.fieldLoading = rmapsNormalizeService.updateRule vm.mlsData.current.id, vm.fieldData

  vm.saveRuleDebounced = _.debounce saveRule, 2000

  config = $scope.selectedMls
  parseRules(config.rules)
  rmapsMlsService.getColumnList(config.id, config.main_property_data.db, config.main_property_data.table)
  .then (fields) ->
    parseFields(fields)
