app = require '../app.coffee'
_ = require 'lodash'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
require '../directives/dragdrop.coffee'
require '../directives/listinput.coffee'
require '../factories/validatorBuilder.coffee'
swflmls_fields = require '../../../../common/samples/swflmls_fields.coffee'

app.controller 'rmapsNormalizeCtrl', [ '$scope', '$state', 'rmapsMlsService', 'rmapsNormalizeService', 'validatorBuilder', ($scope, $state, rmapsMlsService, rmapsNormalizeService, validatorBuilder) ->
  $scope.$state = $state

  $scope.mlsData =
    current: {}

  $scope.fieldData =
    current: {}

  $scope.columns = swflmls_fields # Test data

  $scope.transformOptions = [
    { label: 'Uppercase', value: 'forceUpperCase' },
    { label: 'Lowercase', value: 'forceLowerCase' },
    { label: 'Init Caps', value: 'forceInitCaps' }
  ];

  $scope.categories = [
#      'base',
      'contacts',
      'location',
      'hidden',
      'restrictions',
      'building',
      'sale',
      'listing',
      'details',
      'general',
      'lot',
      'realtor'
      ].map (c) ->
        { label: c[0].toUpperCase() + c.slice(1), items: [] }

  # Load list of MLS
  rmapsMlsService.getConfigs()
  .then (configs) ->
    $scope.mlsConfigs = configs

  # Load saved MLS config and MLS field list
  $scope.selectMls = () ->
    config = $scope.mlsData.current
    rmapsNormalizeService.getRules config.id
    .then (rules) ->
      # todo: place rules into categories here

    rmapsMlsService.getColumnList config.id, config.main_property_data.db, config.main_property_data.table
    .then (columns) ->
      # todo: create un-assigned rules for any fields that weren't already configured

  # Show field options
  $scope.selectField = (field) ->
    config = $scope.mlsData.current
    $scope.fieldData.current = field
    if not field.vOptions
      field.vOptions = {}
    if field.Interpretation.indexOf('Lookup') == 0
      rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.SystemName
      .then (lookups) ->
        field.lookups = lookups

  # Move fields between categories
  $scope.onDrop = (drag, drop, target) ->
    _.pull drag.collection, drag.model
    drop.collection.splice _.indexOf(drop.collection, target), 0, drag.model
    $scope.$evalAsync()
    # todo: save

  # Map configuration options to transform JSON
  $scope.getTransform = () ->
    field = $scope.fieldData.current
    if field.DataType
      options =
        vOptions: field.vOptions
        type: {
          'Int': 'integer'
          'Decimal': 'float'
          'Long': 'float'
          'Character': 'string'
          'Boolean': 'boolean'
          'DateTime': 'datetime'
        }[field.DataType]
      field.transform = validatorBuilder(options)
      console.log field
      # todo: save
]
