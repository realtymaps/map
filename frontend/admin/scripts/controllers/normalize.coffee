app = require '../app.coffee'
_ = require 'lodash'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
require '../directives/dragdrop.coffee'
require '../directives/listinput.coffee'
require '../factories/validatorBuilder.coffee'

app.controller 'rmapsNormalizeCtrl',
['$window', '$scope', '$rootScope', '$state', 'rmapsMlsService', 'rmapsNormalizeService', 'validatorBuilder', 'rmapsevents', 'rmapsParcelEnums',
($window, $scope, $rootScope, $state, rmapsMlsService, rmapsNormalizeService, validatorBuilder, rmapsevents, rmapsParcelEnums) ->

  $scope.$state = $state

  $scope.mlsData =
    current: null

  $scope.fieldData =
    current: null

  $scope.transformOptions =
    'Uppercase': 'forceUpperCase'
    'Lowercase': 'forceLowerCase'
    'Init Caps': 'forceInitCaps'
  $scope.nullifyOptions =
    'True': true
    'False': false
    'Neither': null

  $scope.addressOptions = _.map rmapsParcelEnums.address, (label, key) ->
    label: label
    key: key

  $scope.statusOptions = _.values rmapsParcelEnums.status

  $scope.subStatusOptions = _.values rmapsParcelEnums.subStatus

  $scope.baseRules = validatorBuilder.baseRules

  $scope.categories = {}
  $scope.targetCategories = _.map rmapsParcelEnums.categories, (label, list) ->
    label: label
    list: list
    items: $scope.categories[list] = []

  # CSV Download items
  $scope.csv =
    rowCount: 1000
    getUrl: (rows) ->
      rmapsMlsService.getDataDumpUrl($scope.mlsData.current.id, rows)
  $scope.dlCSV = (url) ->
    $window.open url, "_self"
    return true

  allRules = {}

  # Handles adding rules to categories
  addRule = (rule, list) ->
    category = $scope.categories[list]
    _.extend rule,
      ordering: rule.ordering ? category.length
      config: rule.config || {}
      list: list
    idx = _.sortedIndex(category, rule, 'ordering')
    category.splice idx, 0, allRules[rule.output] = rule

  # Handles adding base rules
  addBaseRule = (rule) ->
    validatorBuilder.validateBase rule
    validatorBuilder.getTransform rule
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
    _.forEach $scope.baseRules, (rule, output) ->
      if !allRules[output]
        rule.output = output
        addBaseRule rule

    # Save base rules
    $scope.baseLoading = rmapsNormalizeService.createListRules $scope.mlsData.current.id, 'base', $scope.categories.base

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

    _.forEach $scope.categories.base, (rule) -> updateAssigned(rule)

  # Show field options
  $scope.selectField = (field) ->
    $scope.showProperties = true
    $scope.fieldData.current = field
    $scope.loadLookups(if field.list == 'base' then allRules[field.input] else field)

  $scope.loadLookups = (field) ->
    if field?._lookups
      $scope.fieldData.current._lookups = field._lookups
      if field._lookups.length <= 50
        $scope.fieldData.current.lookups = field._lookups
    else if field && !field._lookups && field.LookupName
      config = $scope.mlsData.current
      $scope.mlsLoading = rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.LookupName
      .then (lookups) ->
        $scope.fieldData.current._lookups = field._lookups = lookups
        if lookups.length <= 50
          $scope.fieldData.current.lookups = lookups
        $scope.$evalAsync()

  # Move rules between categories
  $scope.onDropCategory = (drag, drop, target) ->
    if drag.model.unselectable
      return
    from = _.find($scope.targetCategories, (c) -> c.items == drag.collection)
    to = _.find($scope.targetCategories, (c) -> c.items == drop.collection)
    idx = _.indexOf(drop.collection, target)
    if to.list != 'unassigned'
      $scope.fieldData.category = to
    from.loading = to.loading = rmapsNormalizeService.moveRule(
      $scope.mlsData.current.id,
      drag.model,
      from,
      to,
      if idx != -1 then idx else 0
    ).then () ->
      $scope.selectField(drag.model)
      $scope.$evalAsync()

  $scope.onDropBaseInput = (drag, drop, target) ->
    field = $scope.fieldData.current
    key = drop.collection
    removed = field.input[key]
    field.input[key] = drag.model.output
    updateAssigned(field)
    updateBase(field, removed)

  # Remove base field input
  $scope.removeBaseInput = (key) ->
    field = $scope.fieldData.current
    removed = field.input[key]
    delete field.input[key]
    delete field.lookups
    delete field.config.choices
    updateBase(field, removed)

  # Move rules to base field config
  $scope.onDropBase = (drag, drop, target) ->
    field = $scope.fieldData.current
    removed = field.input
    field.input = drag.model.output
    $scope.loadLookups(drag.model)
    updateBase(field, removed)

  # Remove base field input
  $scope.removeBase = () ->
    field = $scope.fieldData.current
    removed = field.input
    field.input = null
    delete field.lookups
    delete field.config.choices
    updateBase(field, removed)

  updateBase = (field, removed) ->
    validatorBuilder.getTransform(field)
    validatorBuilder.validateBase(field)
    field.inputString = JSON.stringify(field.input) # for display
    updateAssigned(field, removed)
    saveRule(field)

  updateAssigned = (rule, removed) ->
    if $scope.baseRules[rule.output].group
      delete allRules[removed]?.assigned
      if _.isString rule.input
        allRules[rule.input]?.assigned = true
      else _.forEach rule.input, (input) ->
        allRules[input]?.assigned = true

  # User input triggers this
  $scope.updateRule = () ->
    field = $scope.fieldData.current
    validatorBuilder.getTransform field
    $scope.saveRuleDebounced()

  saveRule = (rule) ->
    $scope.fieldLoading = rmapsNormalizeService.updateRule $scope.mlsData.current.id, rule

  # Separate debounce/timeout for each rule
  saveFns = _.memoize((rule) ->
    _.debounce(_.partial(saveRule, rule), 2000)
  , (rule) -> rule.output)

  $scope.saveRuleDebounced = () ->
    saveFns($scope.fieldData.current)()

  # Dropdown selection, reloads the view
  $scope.selectMls = () ->
    $state.go($state.current, { id: $scope.mlsData.current.id }, { reload: true })

  # Load saved MLS config and RETS fields
  loadMls = (config) ->
    $scope.mlsLoading =
      rmapsNormalizeService.getRules(config.id)
      .then (rules) ->
        parseRules(rules)
        rmapsMlsService.getColumnList(config.id, config.main_property_data.db, config.main_property_data.table)
      .then (fields) ->
        parseFields(fields)

  # Load MLS list
  rmapsMlsService.getConfigs()
  .then (configs) ->
    $scope.mlsConfigs = configs
    if $state.params.id
      $scope.mlsData.current = _.find $scope.mlsConfigs, { id: $state.params.id }
      loadMls($scope.mlsData.current)
]
