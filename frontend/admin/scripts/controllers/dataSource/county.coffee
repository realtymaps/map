app = require '../../app.coffee'

app.controller 'rmapsCountyCtrl',
($window, $scope, $rootScope, $state, rmapsCountyService, rmapsNormalizeService, validatorBuilder, rmapsevents, rmapsParcelEnums, rmapsprincipal) ->

  console.log "#### rmapsCountyService:"
  console.log rmapsCountyService

  # Data service. Initialized once an MLS is selected
  normalizeService = null

  $scope.$state = $state

  $scope.countyData =
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

  $scope.statusOptions = _.values rmapsParcelEnums.status

  $scope.subStatusOptions = _.values rmapsParcelEnums.subStatus

  $scope.baseRules = validatorBuilder.baseRules

  $scope.categories = {}
  $scope.targetCategories = _.map rmapsParcelEnums.categories['county']['tax'], (label, list) ->
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






  # Dropdown selection, reloads the view
  $scope.selectCounty = () ->
    console.log "#### selectCounty(), countyData:"
    console.log $scope.countyData

    $state.go($state.current, { id: $scope.countyData.current.id }, { reload: true })



  updateAssigned = (rule, removed) ->
    if $scope.baseRules[rule.output].group
      delete allRules[removed]?.assigned
      if _.isString rule.input
        allRules[rule.input]?.assigned = true
      else _.forEach rule.input, (input) ->
        allRules[input]?.assigned = true




  allRules = {}

  # Handles adding rules to categories
  addRule = (rule, list) ->
    console.log "#### addRule, rule:"
    console.log rule
    console.log "#### addRule, list:"
    console.log list

    category = $scope.categories[list]
    _.defaults rule,
      ordering: category.length
      list: list
    idx = _.sortedIndex(category, rule, 'ordering')
    category.splice idx, 0, allRules[rule.output] = rule

  # Handles adding base rules
  addBaseRule = (rule) ->
    console.log "#### addBaseRule, rule:"
    console.log rule
    validatorBuilder.buildBaseRule rule
    console.log "#### validatorBuilder.buildBaseRule rule:"
    console.log rule
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

  # Handles parsing fields for display
  parseFields = (fields) ->
    _.forEach fields, (field) ->
      rule = allRules[field.LongName]
      if rule
        _.extend rule, _.pick(field, ['DataType', 'Interpretation', 'LookupName'])
      else
        rule = field
        rule.output = rule.LongName
        addRule rule, 'unassigned'

      validatorBuilder.buildRetsRule rule
      true

    _.forEach $scope.categories.base, (rule) -> updateAssigned(rule)

  # Load saved county config and fields
  loadCounty = (config) ->
    console.log "#### loadCounty, config:"
    console.log config
    normalizeService = new rmapsNormalizeService config.id, 'county', 'tax'
    $scope.countyLoading =
      normalizeService.getRules()
      .then (rules) ->
        console.log "#### loadCounty, rules:"
        console.log rules
        parseRules(rules)
        rmapsCountyService.getColumnList(config.id, 'county', 'tax')
      .then (fields) ->
        console.log "#### loadCounty, fields:"
        console.log fields
        parseFields(fields)

  $scope.getCountyList = () ->
    console.log "#### getCountyList()"
    rmapsCountyService.getConfigs({schemaReady: true})
    .then (configs) ->
      console.log "#### getConfigs, configs:"
      console.log configs
      $scope.countyConfigs = configs
      configs

  $scope.loadReadyCounty = () ->
    $scope.getCountyList()
    .then (configs) ->
      $scope.countyConfigs = configs
      if $state.params.id
        $scope.countyData.current = _.find $scope.countyConfigs, { id: $state.params.id }
        loadCounty($scope.countyData.current)

  # Load MLS list
  # Register the logic that acquires data so it can be evaluated after auth
  $rootScope.registerScopeData () ->
    $scope.loadReadyCounty()


