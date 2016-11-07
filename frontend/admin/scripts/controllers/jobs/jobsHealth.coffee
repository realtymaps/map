app = require '../../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsHealthCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants) ->

  $scope.healthTimerange = '1 day'

  $scope.jobsGrid =
    enableFiltering: true
    enableColumnMenus: false
    showColumnFooter: true
    enablePinning: true
    columnDefs:[
      field: 'load_id'
      displayName: 'Data Source'
      width: 125
      footerCellTemplate: '<div>Totals</div>'
      sort:
        direction: uiGridConstants.ASC
      pinnedLeft: true
    ].concat _.map [
      field: 'load_count'
      displayName: 'Loads'
    ,
      field: 'raw'
      displayName: 'Raw Rows'
    ,
      field: 'inserted'
      displayName: 'Inserted'
    ,
      field: 'updated'
      displayName: 'Updated'
    ,
      field: 'deleted'
      displayName: 'Deleted'
    ,
      field: 'touched'
      displayName: 'Touched'
    ,
      field: 'invalid'
      displayName: 'Invalid'
    ,
      field: 'unvalidated'
      displayName: 'Unvalidated'
    ,
      field: 'null_geometry'
      displayName: 'No Geom'
    ,
      field: 'out_of_date'
      displayName: 'Outdated (2 days)'
      width: 150
    ,
      field: 'ungrouped_fields'
      displayName: 'Ungrouped'
      width: 125
    ], (num) ->
      _.defaults num,
        aggregationType: uiGridConstants.aggregationTypes.sum
        type: 'number'
        width: 100
        cellClass: 'numberCell'
        footerCellTemplate: '<div class="numberCell">{{ col.getAggregationValue() }}</div>'

  $scope.loadHealth = () ->
    $scope.jobsBusy = rmapsJobsService.getHealth($scope.healthTimerange)
    .then (health) ->
      $scope.jobsGrid.data = health.plain()

  $scope.loadHealth($scope.healthTimerange)
