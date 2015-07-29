app = require '../app.coffee'
GridController = require '../../../common/scripts/utils/gridController.coffee'

app.controller 'rmapsJobsQueueCtrl', ($scope, $rootScope, $injector, Restangular, rmapsJobsService) ->

  $scope.getData = rmapsJobsService.getQueue

  @gridName = 'Queue'

  @columnDefs = [
      field: 'name'
      displayName: 'Name'
      width: 150
      enableCellEdit: false
    ,
      field: 'lock_id'
      displayName: 'Lock ID'
      width: 150
      enableCellEdit: false
      defaultValue: () -> Math.floor(Math.random() * 1000000000)
    ,
      field: 'processes_per_dyno'
      displayName: 'Processes Per Dyno'
      type: 'number'
      width: 175
      defaultValue: 1
    ,
      field: 'subtasks_per_process'
      displayName: 'Subtasks Per Process'
      type: 'number'
      width: 175
      defaultValue: 1
    ,
      field: 'priority_factor'
      displayName: 'Priority Factor'
      type: 'number'
      width: 150
      defaultValue: 1.0
    ,
      field: 'active'
      displayName: 'Active'
      type: 'boolean'
      width: 150
      defaultValue: false
  ]

  $injector.invoke GridController, this,
    $scope: $scope
    $rootScope: $rootScope
    Restangular: Restangular
