app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsQueueCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  $scope.jobsGrid =
    enableColumnMenus: false
    onRegisterApi: (gridApi) ->
      gridApi.edit.on.afterCellEdit $scope, (rowEntity, colDef, newValue, oldValue) ->
        $scope.$apply()
        rowEntity.save()
    columnDefs:[
      field: 'name'
      displayName: 'Name'
      width: 150
    ,
      field: 'lock_id'
      displayName: 'Lock ID'
      width: 150
    ,
      field: 'processes_per_dyno'
      displayName: 'Processes Per Dyno'
      width: 100
    ,
      field: 'subtasks_per_process'
      displayName: 'Subtasks Per Process'
      width: 150
    ,
      field: 'priority_factor'
      displayName: 'Priority Factor'
      width: 100
    ,
      field: 'active'
      displayName: 'Active'
      width: 150
    ]

  $scope.loadQueues = () ->
    $scope.jobsBusy = rmapsJobsService.getQueues()
    .then (queues) ->
      $scope.jobsGrid.data = queues

  $rootScope.registerScopeData () ->
    $scope.loadQueues()
