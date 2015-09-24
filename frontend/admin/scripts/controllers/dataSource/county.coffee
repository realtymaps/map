app = require '../../app.coffee'
_ = require 'lodash'
require '../../directives/dragdrop.coffee'
require '../../directives/listinput.coffee'


app.controller 'rmapsCountyCtrl',
($window, $scope, $rootScope, $state, $log, rmapsCountyService, rmapsNormalizeService, validatorBuilder, rmapsevents, rmapsParcelEnums, rmapsprincipal) ->

  $scope.$state = $state

  $scope.countyData =
    current: null
    dataListType: null
    dataSourceType:
      id: 'county'
      name: 'County'

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

  $scope.dataListTypes = [
    id: 'tax'
    name: 'Tax'
  ,
    id: 'deed'
    name: 'Deed'
  ]

  $scope.statusOptions = _.values rmapsParcelEnums.status

  $scope.subStatusOptions = _.values rmapsParcelEnums.subStatus

  $scope.getTargetCategories = (dataSourceType, dataListType) ->
    $scope.categories = {}
    $scope.targetCategories = _.map rmapsParcelEnums.categories[dataSourceType][dataListType], (label, list) ->
      label: label
      list: list
      items: $scope.categories[list] = []

  $scope.getBaseRules = (dataSourceType, dataListType) ->
    $scope.baseRules = validatorBuilder.baseRules[dataSourceType][dataListType]

  allRules = {}

  # Handles adding rules to categories
  addRule = (rule, list) ->
    category = $scope.categories[list]
    _.defaults rule,
      ordering: category.length
      list: list
    idx = _.sortedIndex(category, rule, 'ordering')
    category.splice idx, 0, allRules[rule.output] = rule

  # Handles adding base rules
  addBaseRule = (rule) ->
    validatorBuilder.buildBaseRule($scope.countyData.dataSourceType.id) rule
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
    _.forEach $scope.baseRules, (rule, output) ->
      if !allRules[output]
        rule.output = output
        addBaseRule rule

    # Save base rules
    $scope.baseLoading = normalizeService.createListRules 'base', $scope.categories.base

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

      # It is important to save the data type so a transform can be regenerated entirely from the config
      rule.config = _.defaults rule.config ? {}, DataType: field.DataType
      validatorBuilder.buildDataRule rule
      true

    _.forEach $scope.categories.base, (rule) -> updateAssigned(rule)

  # Show field options
  $scope.selectField = (field) ->
    if field.list != 'unassigned' && field.list != 'base'
      $scope.fieldData.category = _.find $scope.targetCategories, 'list', field.list
    $scope.fieldData.current = field
    $scope.loadLookups(if field.list == 'base' then allRules[field.input] else field)

  $scope.loadLookups = (field) ->
    if field?._lookups
      $scope.fieldData.current._lookups = field._lookups
      if field._lookups.length <= 50
        $scope.fieldData.current.lookups = field._lookups
    else if field && !field._lookups && field.LookupName
      $log.debug "#### has lookup types!!!"
      config = $scope.mlsData.current
      $scope.fieldData.current.lookups = []
      $scope.$evalAsync()
      # $scope.mlsLoading = rmapsMlsService.getLookupTypes config.id, config.listing_data.db, field.LookupName
      # .then (lookups) ->

      #   $log.debug "#### lookups:"
      #   $log.debug lookups.plain()

      #   $scope.fieldData.current._lookups = field._lookups = lookups
      #   if lookups.length <= 50
      #     $scope.fieldData.current.lookups = lookups
      #   $scope.$evalAsync()

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
    delete field.config.map
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
    delete field.config.map
    updateBase(field, removed)

  updateBase = (field, removed) ->
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
    if field.config.advanced && !field.transform
      field.transform = field.getTransformString $scope.mlsData.current.data_rules
    else
      field.transform = null
    $scope.saveRuleDebounced()

  saveRule = (rule) ->
    $scope.fieldLoading = normalizeService.updateRule rule

  # Separate debounce/timeout for each rule
  saveFns = _.memoize((rule) ->
    _.debounce(_.partial(saveRule, rule), 2000)
  , (rule) -> rule.output)

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
    normalizeService = new rmapsNormalizeService config.current.id, config.dataSourceType.id, config.dataListType.id
    $scope.countyLoading =
      normalizeService.getRules()
      .then (rules) ->
        parseRules(rules)
        rmapsCountyService.getColumnList(config.current.id, config.dataSourceType.id, config.dataListType.id)
      .then (fields) ->
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
  # Register the logic that acquires data so it can be evaluated after auth
  $rootScope.registerScopeData () ->
    $scope.loadReadyCounty()


