app = require '../../app.coffee'
_ = require 'lodash'
adminRoutes = require '../../../../../common/config/routes.admin.coffee'
require '../../services/mlsConfig.coffee'
require '../../services/normalize.coffee'
require '../../directives/listinput.coffee'
require '../../factories/validatorBuilder.coffee'

###
    ****************************************************************************************
    * When changing this file, look at county.coffee for possible redundant changes needed *
    ****************************************************************************************
###


app.controller 'rmapsNormalizeCtrl',
($window, $scope, $rootScope, $state, $log, rmapsMlsService, rmapsNormalizeFactory, rmapsValidatorBuilderService, rmapsEventConstants, rmapsParcelEnums, rmapsPrincipalService, rmapsAdminConstants) ->

  $scope.$state = $state

  $scope.JSON = JSON

  $scope.mlsData =
    current: null

  $scope.fieldData =
    current: null

  $scope.transformOptions =
    'UPPERCASE': 'forceUpperCase'
    'lowercase': 'forceLowerCase'
    'Init Caps': 'forceInitCaps'

  $scope.nullifyOptions =
    'True': true
    'False': false
    'Neither': null

  $scope.dateFormats = [
    'YYYY-MM-DD'
    'YYYYMMDD'
    'MMDDYYYY'
    'YYYY-MM-DD[T]HH:mm:ss'
  ]

  $scope.statusOptions = _.values rmapsParcelEnums.status

  $scope.subStatusOptions = _.values rmapsParcelEnums.subStatus

  $scope.propertyTypeOptions = _.values rmapsParcelEnums.propertyType

  $scope.baseRules = rmapsValidatorBuilderService.getBaseRules('mls', 'listing')

  $scope.categories = {}
  $scope.targetCategories = _.map rmapsParcelEnums.categories['mls']['listing'], (label, list) ->
    label: label
    list: list
    items: $scope.categories[list] = []

  # CSV Download items
  $scope.csv =
    rowCount: 1000
    getUrl: (rows) ->
      rmapsMlsService.getDataDumpUrl($scope.mlsData.current.id, rows)

  $scope.dlCSV = (url) ->
    $window.open url, '_self'
    return true

  allRules = {}

  # Handles adding rules to categories
  addRule = (rule, list) ->
    category = $scope.categories[list]
    rule.ordering ?= category.length
    rule.list ?= list
    idx = _.sortedIndex(category, rule, 'ordering')
    allRules[if list == 'base' then rule.output else rule.input] = rule
    category.splice idx, 0, rule

  # Handles adding base rules
  addBaseRule = (rule) ->
    rmapsValidatorBuilderService.buildBaseRule('mls', 'listing') rule
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
        addBaseRule rule

    # correct ordering in case there were gaps (from someone mucking with the db manually)
    for name,list of $scope.categories when name != 'unassigned'
      for rule,index in list
        rule.ordering = index

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
        rule.input = rule.LongName
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
    if field.list == 'base'
      $scope.loadLookups(allRules[field.input], field)
    else
      $scope.loadLookups(field)

  $scope.loadLookups = (field, target) ->
    if !target
      target = field
    setLookups = (lookups) ->
      target._lookups = field._lookups = lookups
      if field._lookups.length <= rmapsAdminConstants.dataSource.lookupThreshold
        target.lookups = field._lookups
    if field?._lookups
      setLookups(field._lookups)
    else if field && !field._lookups && field.LookupName
      config = $scope.mlsData.current
      $scope.mlsLoading = rmapsMlsService.getLookupTypes config.id, config.listing_data.db, field.LookupName
      .then (lookups) ->
        setLookups(lookups)
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
    $scope.loadLookups(drag.model, field)
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
        field.transform = field.getTransformString $scope.mlsData.current.data_rules
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
  $scope.selectMls = () ->
    $state.go($state.current, { id: $scope.mlsData.current.id }, { reload: true })

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

  $scope.updateDataRules = _.debounce () ->
    rmapsMlsService.update $scope.mlsData.current.id, data_rules: $scope.mlsData.current.data_rules
  , 2000

  $scope.getTransform = () ->
    if $scope.fieldData.current?.getTransformString?
      $scope.fieldData.current.getTransformString $scope.mlsData.current.data_rules

  # Data service. Initialized once an MLS is selected
  normalizeService = null

  # Load saved MLS config and RETS fields
  loadMls = (config) ->
    normalizeService = new rmapsNormalizeFactory config.id, 'mls', 'listing'
    $scope.mlsLoading =
      normalizeService.getRules()
      .then (rules) ->
        parseRules(rules)
      .then () ->
        rmapsMlsService.getColumnList(config.id, config.listing_data.db, config.listing_data.table)
      .then (fields) ->
        parseFields(fields)

    _.forEach $scope.baseRules, (rule, baseRulesKey) ->
      $scope.mlsLoading = $scope.mlsLoading.then () ->
        $scope.loadLookups(allRules[allRules[baseRulesKey].input], allRules[baseRulesKey])

  $scope.getMlsList = () ->
    rmapsMlsService.getConfigs({schemaReady: true})
    .then (configs) ->
      $scope.mlsConfigs = configs
      configs

  $scope.loadReadyMls = () ->
    $scope.getMlsList()
    .then (configs) ->
      $scope.mlsConfigs = configs
      if $state.params.id
        $scope.mlsData.current = _.find $scope.mlsConfigs, { id: $state.params.id }
        loadMls($scope.mlsData.current)

  # Load MLS list
  $scope.loadReadyMls()
