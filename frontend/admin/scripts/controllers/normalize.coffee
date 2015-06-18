app = require '../app.coffee'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
require '../directives/dragdrop.coffee'
require '../directives/listinput.coffee'
swflmls_fields = require '../../../../common/samples/swflmls_fields.coffee'

app.controller 'rmapsNormalizeCtrl', [ '$scope', '$state', 'rmapsMlsService', 'rmapsNormalizeService', ($scope, $state, rmapsMlsService, rmapsNormalizeService) ->
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

  rmapsMlsService.getConfigs()
  .then (configs) ->
    $scope.mlsConfigs = configs

  $scope.selectMls = () ->
    config = $scope.mlsData.current
    rmapsNormalizeService.getRules config.id
    .then (rules) ->
      console.log(rules)

    rmapsMlsService.getColumnList config.id, config.main_property_data.db, config.main_property_data.table
    .then (columns) ->
      # $scope.columns = columns

  $scope.selectField = (field) ->
    config = $scope.mlsData.current
    $scope.fieldData.current = field
    if field.Interpretation.indexOf('Lookup') == 0
      rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.SystemName
      .then (lookups) ->
        field.lookups = lookups

  $scope.onDrop = (drag, drop, target) ->
    _.pull drag.collection, drag.model
    drop.collection.splice _.indexOf(drop.collection, target), 0, drag.model
    $scope.$evalAsync()

  $scope.$watchCollection 'fieldData.current', (newValue, oldValue) ->
    console.log newValue
]
