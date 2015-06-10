app = require '../app.coffee'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
swflmls_fields = require '../../../../common/samples/swflmls_fields.coffee'

app.controller 'rmapsNormalizeCtrl', [ '$scope', '$state', 'rmapsMlsService', 'rmapsNormalizeService', ($scope, $state, rmapsMlsService, rmapsNormalizeService) ->
  $scope.$state = $state

  $scope.mlsData =
    current: {}

  $scope.columns = swflmls_fields # Test data

  $scope.categories = [
      'base',
      'hidden',
      'base'
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
      $scope.columns = columns
]
