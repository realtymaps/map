app = require '../app.coffee'
_ = require 'lodash'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
require '../directives/dragdrop.coffee'
require '../directives/listinput.coffee'
require '../factories/validatorBuilder.coffee'


app.controller 'rmapsNormalizeCtrl',
['$window', '$scope', '$rootScope', '$state', 'rmapsMlsService', 'rmapsNormalizeService', 'validatorBuilder', 'rmapsevents', 'rmapsParcelEnums', 'rmapsprincipal',
($window, $scope, $rootScope, $state, rmapsMlsService, rmapsNormalizeService, validatorBuilder, rmapsevents, rmapsParcelEnums, rmapsprincipal) ->

  $scope.$state = $state

  $scope.mlsData =
    current: null

  $scope.fieldData =
    current: null

  $scope.transformOptions =
    'Uppercase': 'forceUpperCase'
    'Lowercase': 'forceLowerCase'
    'Init Caps': 'forceInitCaps'

  $scope.addressOptions = _.map rmapsParcelEnums.address, (label, key) ->
    label: label
    key: key

  $scope.statusOptions = _.values rmapsParcelEnums.status

  $scope.subStatusOptions = _.values rmapsParcelEnums.subStatus

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

  # Load MLS list
  restoreState = () ->
    # don't start pulling mls data unless identity checks out
    rmapsprincipal.getIdentity()
    .then (identity) ->
      if not identity?.user?
        return $location.path(adminRoutes.urls.login)
      rmapsMlsService.getConfigs()
      .then (configs) ->
        $scope.mlsConfigs = configs

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
    addRule rule, 'base'

  # Handles parsing existing rules for display
  parseRules = (rules) ->
    # Load existing base rules first
    _.forEach _.where(rules, list: 'base'), (rule) ->
      addBaseRule rule
    # Create base rules that don't exist yet
    _.forEach validatorBuilder.baseRules, (rule, output) ->
      if !allRules[output]
        rule.output = output
        addBaseRule rule
    # Create remaining rules
    _.forEach _.where(rules, (r) -> r.list != 'base'), (rule) ->
      if allRules[rule.output]?.list == 'base'
        validatorBuilder.validateBase rule
        rule.unselectable = true
      addRule rule, rule.list

    # Validate base rules
    $scope.baseFinished = _.every $scope.categories.base, valid: true

    # Save base rules
    $scope.baseLoading = rmapsNormalizeService.createListRules $scope.mlsData.current.id, 'base', $scope.categories.base

  # Handles parsing RETS fields for display
  parseFields = (fields) ->
    _.forEach fields, (field) ->
      rule = allRules[field.LongName]
      if rule
        _.extend rule, _.pick(field, ['DataType', 'Interpretation', 'LookupName'])
      else
        field.output = field.LongName
        addRule field, 'unassigned'

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
      $scope.mlsLoading = rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.LookupName
      .then (lookups) ->
        $scope.fieldData.current.lookups = field.lookups = lookups
        $scope.$evalAsync()

  # Move rules between categories
  $scope.onDropCategory = (drag, drop, target) ->
    if drag.model.unselectable
      return
    from = _.find($scope.targetCategories, (c) -> c.items == drag.collection)
    to = _.find($scope.targetCategories, (c) -> c.items == drop.collection)
    from.loading = to.loading = rmapsNormalizeService.moveRule(
      $scope.mlsData.current.id,
      drag.model,
      from,
      to,
      _.indexOf(drop.collection, target)
    ).then () ->
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
    validatorBuilder.validateBase(field)
    field.inputString = JSON.stringify(field.input) # for display
    $scope.baseFinished = _.every $scope.categories.base, valid: true
    saveRule()

  # User input triggers this
  $scope.updateRule = () ->
    field = $scope.fieldData.current
    field.transform = validatorBuilder.getTransform field
    $scope.saveRuleDebounced()

  saveRule = () ->
    $scope.fieldLoading = rmapsNormalizeService.updateRule $scope.mlsData.current.id, $scope.fieldData.current

  $scope.saveRuleDebounced = _.debounce saveRule, 2000



  $scope.$onRootScope rmapsevents.principal.login.success, () ->
    restoreState()

  if rmapsprincipal.isIdentityResolved() && rmapsprincipal.isAuthenticated()
    restoreState()

]
