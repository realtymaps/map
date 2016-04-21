app = require '../../app.coffee'
_ = require 'lodash'
require '../../directives/listinput.coffee'

###
    *******************************************************************************************
    * When changing this file, look at normalize.coffee for possible redundant changes needed *
    *******************************************************************************************
###

app.controller 'rmapsCountyCtrl',
($window, $scope, $rootScope, $state, $log, rmapsCountyService, rmapsNormalizeFactory, rmapsValidatorBuilderService, rmapsEventConstants, rmapsParcelEnums, rmapsPrincipalService, rmapsAdminConstants) ->

  $scope.$state = $state

  $scope.JSON = JSON

  $scope.countyData =
    current: null
    dataListType: null
    dataSourceType:
      id: 'county'
      name: 'County'

  $scope.fieldData =
    current: null
    totalCount: 0

  $scope.transformOptions =
    'UPPERCASE': 'forceUpperCase'
    'lowercase': 'forceLowerCase'
    'Init Caps': 'forceInitCaps'

  $scope.nullifyOptions =
    'True': true
    'False': false
    'Neither': null

  $scope.dataListTypes = [
    id: 'tax'
    name: 'Tax'
  ,
    id: 'deed'
    name: 'Deed'
  ,
    id: 'mortgage'
    name: 'mortgage'
  ]

  $scope.dateFormats = [
    'YYYY-MM-DD'
    'YYYYMMDD'
    'MMDDYYYY'
    'YYYY-MM-DD[T]HH:mm:ss'
  ]

  $scope.getTargetCategories = (dataSourceType, dataListType) ->
    $scope.categories = {}
    $scope.targetCategories = _.map rmapsParcelEnums.categories[dataSourceType][dataListType], (label, list) ->
      label: label
      list: list
      items: $scope.categories[list] = []

  $scope.getBaseRules = (dataSourceType, dataListType) ->
    $scope.baseRules = rmapsValidatorBuilderService.getBaseRules(dataSourceType, dataListType)

  allRules = {}

  # Handles adding rules to categories
  addRule = (rule, list) ->
    category = $scope.categories[list]
    _.defaults rule,
      ordering: category.length
      list: list
    idx = _.sortedIndex(category, rule, 'ordering')
    allRules[if list == 'base' then rule.output else rule.input] = rule
    category.splice idx, 0, rule

  # Handles adding base rules
  addBaseRule = (rule) ->
    rmapsValidatorBuilderService.buildBaseRule($scope.countyData.dataSourceType.id, $scope.countyData.dataListType.id) rule
    addRule rule, 'base'

  # Handles parsing existing rules for display
  parseRules = (rules) ->
    # Load existing rules first
    _.forEach rules, (rule) ->
      if rule.list == 'base'
        addBaseRule rule
      else
        addRule rule, rule.list
        # Show all rules in unassigned
        addRule rule, 'unassigned'

    # Create base rules that don't exist yet
    _.forEach $scope.baseRules, (rule, baseRulesKey) ->
      if !allRules[baseRulesKey]
        rule.output = baseRulesKey
        addBaseRule(rule)

    # Save base rules
    if 'base' of $scope.categories
      $scope.baseLoading = normalizeService.createListRules 'base', $scope.categories.base

  # Handles parsing RETS fields for display
  parseFields = (fields) ->
    _.forEach fields, (field) ->
      rule = allRules[field.LongName]
      if rule
        _.extend rule, _.pick(field, ['DataType', 'Interpretation', 'LookupName'])
      else
        rule = field
        rule.input = rule.LongName
        rule.output = rule.LongName
        addRule rule, 'unassigned'

      # It is important to save the data type so a transform can be regenerated entirely from the config
      rule.config = _.defaults rule.config ? {}, DataType: field.DataType
      rmapsValidatorBuilderService.buildDataRule rule
      true
    if 'base' of $scope.categories
      updateAssigned()

  # Show field options
  $scope.selectField = (field) ->
    if field.list != 'unassigned' && field.list != 'base'
      $scope.fieldData.category = _.find $scope.targetCategories, 'list', field.list
    $scope.fieldData.current = field
    $scope.loadLookups(if field.list == 'base' then allRules[field.output] else field)

  $scope.loadLookups = (field) ->
    if field?._lookups
      $scope.fieldData.current._lookups = field._lookups
      if field._lookups.length <= rmapsAdminConstants.dataSource.lookupThreshold
        $scope.fieldData.current.lookups = field._lookups
    else if field && !field._lookups && field.LookupName && field.Interpretation
      config = $scope.countyData.current
      $scope.countyLoading = rmapsCountyService.getLookupTypes($scope.countyData.current.id, config.dataListType.id, field.LookupName)
      .then (lookups) ->
        $scope.fieldData.current._lookups = field._lookups = lookups
        if lookups.length <= rmapsAdminConstants.dataSource.lookupThreshold
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
    from.loading = to.loading = normalizeService.moveRule(
      drag.model,
      from,
      to,
      if idx != -1 then idx else drop.collection.length
    ).then () ->
      $scope.selectField(drag.model)
      $scope.$evalAsync()

  $scope.onDropBaseInput = (drag, drop, target) ->
    field = $scope.fieldData.current
    key = drop.collection
    removed = field.input[key]
    field.input[key] = drag.model.input
    updateAssigned()
    updateBase(field, removed)

  # Remove base field input
  $scope.removeBaseInput = (key) ->
    field = $scope.fieldData.current
    removed = field.input[key]
    delete field.input[key]
    delete field.lookups
    delete field.config.map
    updateBase(field, removed)

  # Move rules to base field config
  $scope.onDropBase = (drag, drop, target) ->
    field = $scope.fieldData.current
    removed = field.input
    field.input = drag.model.input
    $scope.loadLookups(drag.model)
    updateBase(field, removed)

  # Remove base field input
  $scope.removeBase = () ->
    field = $scope.fieldData.current
    removed = field.input
    field.input = null
    delete field.lookups
    delete field.config.map
    updateBase(field, removed)

  $scope.hideUnassigned = () ->
    unassigned = _.find($scope.targetCategories, 'list', 'unassigned')
    hidden = _.find($scope.targetCategories, 'list', 'hidden')
    toMove = _.filter unassigned.items, 'list', 'unassigned'
    unassigned.loading = hidden.loading = normalizeService.moveUnassigned toMove, hidden

  updateBase = (field, removed) ->
    updateAssigned()
    saveRule(field)

  updateAssigned = () ->
    for checkRule of allRules
      delete allRules[checkRule]?.assigned
    for baseRuleName of $scope.baseRules
      baseRule = allRules[baseRuleName]
      if _.isString baseRule.input
        allRules[baseRule.input]?.assigned = true
      else _.forEach baseRule.input, (input) ->
        allRules[input]?.assigned = true

  # User input triggers this
  $scope.updateRule = () ->
    field = $scope.fieldData.current
    if field.config.advanced
      if !field.transform
        field.transform = field.getTransformString $scope.countyData.current.data_rules
    else
      field.transform = null
    $scope.saveRuleDebounced()

  saveRule = (rule) ->
    $scope.fieldLoading = normalizeService.updateRule rule

  # Separate debounce/timeout for each rule
  saveFns = _.memoize((rule) ->
    _.debounce(_.partial(saveRule, rule), 2000)
  , (rule) -> if rule.list == 'base' then rule.output else rule.input)

  $scope.saveRuleDebounced = () ->
    saveFns($scope.fieldData.current)()

  # Dropdown selection, reloads the view
  $scope.selectCounty = () ->
    if $scope.countyData.current.id and $scope.countyData.dataListType
      $state.go($state.current, { id: $scope.countyData.current.id, list: $scope.countyData.dataListType.id }, { reload: true })

  # Show rules without metadata first, then unassigned followed by assigned
  $scope.orderValid = (rule) -> !!rule.DataType
  $scope.orderList = (rule) -> rule.list != 'unassigned'

  $scope.removeRule = () ->
    rule = $scope.fieldData.current
    from = _.find $scope.targetCategories, 'list', rule.list
    to = _.find $scope.targetCategories, 'list', 'unassigned'
    from.loading = to.loading = normalizeService.moveRule(
      rule,
      from,
      to,
      0
    ).then () ->
      _.pull to.items, rule
      $scope.fieldData.current = null
      $scope.$evalAsync()

  $scope.getTransform = () ->
    if $scope.fieldData.current
      $scope.fieldData.current.getTransformString $scope.countyData.current.data_rules

  # Data service. Initialized once an MLS is selected
  normalizeService = null

  # Load saved county config and fields
  loadCounty = (config) ->
    $scope.getTargetCategories(config.dataSourceType.id, config.dataListType.id)
    $scope.getBaseRules(config.dataSourceType.id, config.dataListType.id)
    normalizeService = new rmapsNormalizeFactory config.current.id, config.dataSourceType.id, config.dataListType.id
    $scope.countyLoading =
      normalizeService.getRules()
      .then (rules) ->
        parseRules(rules)
        rmapsCountyService.getColumnList(config.current.id, config.dataListType.id)
      .then (fields) ->
        $scope.fieldData.totalCount = fields.plain().length
        parseFields(fields)

  $scope.getCountyList = () ->
    rmapsCountyService.getConfigs({schemaReady: true})
    .then (configs) ->
      $scope.countyConfigs = configs
      configs

  $scope.loadReadyCounty = () ->
    $scope.getCountyList()
    .then (configs) ->
      $scope.countyConfigs = configs
      $scope.$evalAsync()
      if $state.params.id
        $scope.countyData.current = _.find $scope.countyConfigs, { id: $state.params.id }
        $scope.countyData.dataListType = _.find $scope.dataListTypes, { id: $state.params.list }
        loadCounty($scope.countyData)

  # Load MLS list
  $scope.loadReadyCounty()
