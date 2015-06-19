app = require '../app.coffee'
_ = require 'lodash'
Promise = require 'bluebird'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
require '../directives/dragdrop.coffee'
require '../directives/listinput.coffee'
require '../factories/validatorBuilder.coffee'

app.controller 'rmapsNormalizeCtrl', [ '$scope', '$state', 'rmapsMlsService', 'rmapsNormalizeService', 'validatorBuilder', ($scope, $state, rmapsMlsService, rmapsNormalizeService, validatorBuilder) ->
  $scope.$state = $state

  $scope.mlsData =
    current: null

  $scope.fieldData =
    current: null

  $scope.transformOptions = [
    { label: 'Uppercase', value: 'forceUpperCase' },
    { label: 'Lowercase', value: 'forceLowerCase' },
    { label: 'Init Caps', value: 'forceInitCaps' }
  ];

  $scope.allCategories = {}

  $scope.categories = [
      list: 'hidden'
      label: 'Hidden'
    ,
      list: 'general'
      label: 'General'
    ,
      list: 'details'
      label: 'Details'
    ,
      list: 'listing'
      label: 'Listing'
    ,
      list: 'building'
      label: 'Building'
    ,
      list: 'lot'
      label: 'Lot'
    ,
      list: 'location'
      label: 'Location & Schools'
    ,
      list: 'dimensions'
      label: 'Room Dimensions'
    ,
      list: 'restrictions'
      label: 'Taxes, Fees, and Restrictions'
    ,
      list: 'contacts'
      label: 'Listing Contacts (realtor only)'
    ,
      list: 'realtor'
      label: 'Listing Details (realtor only)'
    ,
      list: 'sale'
      label: 'Sale Details (realtor only)'
  ].map (c) ->
    $scope.allCategories[c.list] = c
    _.extend c, items: []

  $scope.unassigned =
    list: 'unassigned'
    label: 'Unassigned'
    items: []

  $scope.allCategories['base'] =
    list: 'base'
    label: 'Filters'
    items: []

  $scope.allRules = {}

  # Load list of MLS
  rmapsMlsService.getConfigs()
  .then (configs) ->
    $scope.mlsConfigs = configs

  # Load saved MLS config and MLS field list
  $scope.selectMls = () ->
    config = $scope.mlsData.current
    $scope.mlsLoading =
      rmapsNormalizeService.getRules(config.id)
      .then (rules) ->
        # Regular rule
        _.forEach _.where(rules, (r) -> !r.input?), (rule) ->
          list = $scope.allCategories[rule.list]
          if not $scope.allRules[rule.output]
            $scope.allRules[rule.output] = rule
            rule.label = rule.output
            list.items.push(rule)
          else
            _.extend $scope.allRules[rule.output], rule

        addFilter = (rule, keys) ->
          list = $scope.allCategories[rule.list]
          _.forEach keys, (key) ->
            if $scope.allRules[key]
              $scope.allRules[key].assigned = true
            else
              $scope.unassigned.items.push(
                $scope.allRules[key] =
                assigned: true
                label: rule.key
              )
          list.items.push $scope.allRules[rule.output] =
            _.extend rule,
            composite: true
            label: rule.output

        # Filter, simple
        _.forEach _.where(rules, (r) -> _.isString r.input), (rule) ->
          addFilter(rule, [rule.input])

        # Filter, array
        _.forEach _.where(rules, (r) -> _.isArray r.input), (rule) ->
          addFilter(rule, rule.input)

        # Filter, object
        _.forEach _.where(rules, (r) -> _.isPlainObject r.input), (rule) ->
          addFilter(rule, _.values(rule.input))

        rmapsMlsService.getColumnList(config.id, config.main_property_data.db, config.main_property_data.table)
      .then (columns) ->
        _.forEach columns, (c) ->
          rule = $scope.allRules[c.LongName]
          if rule and not rule.LongName
            _.extend rule, c, label: c.LongName
          else
            $scope.unassigned.items.push _.extend c, label: c.LongName # todo load defaults

  # Show field options
  $scope.selectField = (field) ->
    config = $scope.mlsData.current
    $scope.fieldData.current = field
    field.type = lookupType(field)
    if not field.vOptions
      field.vOptions = {}
    if field.type?.name == 'string' and field.Interpretation.indexOf('Lookup') == 0 and not field.lookups
      $scope.fieldLoading = rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.SystemName
      .then (lookups) ->
        field.lookups = lookups

  # Move fields between categories
  $scope.onDropCategory = (drag, drop, target) ->
    _.pull drag.collection, drag.model
    drop.collection.splice _.indexOf(drop.collection, target), 0, drag.model
    $scope.$evalAsync()
    # todo: save

  # Map configuration options to transform JSON
  $scope.getTransform = () ->
    field = $scope.fieldData.current
    if field.DataType
      options =
        vOptions: _.pick field.vOptions, (v) -> v?
        type: lookupType(field)?.name
      field.transform = validatorBuilder(options)
      console.log field
      # todo: save

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
