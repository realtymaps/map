app = require '../../app.coffee'

app.controller 'rmapsJobsSubtaskCtrl', ($scope, $rootScope, $injector, Restangular, rmapsJobsService, rmapsGridFactory, uiGridConstants) ->
  $scope.getData = rmapsJobsService.getSubtask

  $scope.gridName = 'Subtask'

  new rmapsGridFactory $scope,
    enableFiltering: true
    columnDefs: [
        field: 'name'
        displayName: 'Name'
        width: 200
        enableCellEdit: false
        pinnedLeft: true
      ,
        field: 'task_name'
        displayName: 'Task'
        width: 125
        defaultValue: ''
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'step_num'
        displayName: 'Step#'
        type: 'number'
        width: 75
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'queue_name'
        displayName: 'Queue'
        width: 125
        defaultValue: ''
        cellClass: 'clickable-cell'
      ,
        field: 'data'
        displayName: 'Data'
        type: 'object'
        enableCellEdit: true
        editableCellTemplate: require('../../../html/views/templates/jsonInput.jade')()
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'retry_delay_minutes'
        displayName: 'Retry Delay min'
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'retry_max_count'
        displayName: 'Max Retries'
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'warn_timeout_minutes'
        displayName: 'Warn TO min'
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'kill_timeout_minutes'
        displayName: 'Kill TO min'
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'auto_enqueue'
        displayName: 'Auto Enqueue?'
        type: 'boolean'
        defaultValue: true
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'active'
        displayName: 'Active?'
        type: 'boolean'
        defaultValue: true
        width: 125
        cellClass: 'clickable-cell'
    ]
