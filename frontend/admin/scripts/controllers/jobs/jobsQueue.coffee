app = require '../../app.coffee'

app.controller 'rmapsJobsQueueCtrl', ($scope, $log, $rootScope, $injector, Restangular, rmapsJobsService, rmapsGridFactory) ->
  $scope.getData = rmapsJobsService.getQueue

  $scope.gridName = 'Queue'

  new rmapsGridFactory $scope,
    enableFiltering: true
    columnDefs: [
        field: 'name'
        displayName: 'Name'
        width: 150
        enableCellEdit: false
        pinnedLeft: true
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
        cellClass: 'clickable-cell'
        handleNull: true
      ,
        field: 'subtasks_per_process'
        displayName: 'Subtasks Per Process'
        type: 'number'
        width: 175
        defaultValue: 1
        cellClass: 'clickable-cell'
        handleNull: true
      ,
        field: 'priority_factor'
        displayName: 'Priority Factor'
        type: 'number'
        width: 150
        defaultValue: 1.0
        cellClass: 'clickable-cell'
        handleNull: true
      ,
        field: 'active'
        displayName: 'Active'
        type: 'boolean'
        width: 150
        defaultValue: false
        cellClass: 'clickable-cell'
    ]
