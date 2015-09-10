app = require '../app.coffee'

app.controller 'rmapsJobsSubtaskCtrl', ($scope, $rootScope, $injector, Restangular, rmapsJobsService, rmapsGridFactory, uiGridConstants) ->

  $scope.getData = rmapsJobsService.getSubtask

  $scope.nameFilters = ""

  $scope.gridName = 'Subtask'

  $scope.columnDefs = [
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
    ,
      field: 'step_num'
      displayName: 'Step#'
      type: 'number'
      width: 75
      sort:
        direction: uiGridConstants.ASC
    ,
      field: 'queue_name'
      displayName: 'Queue'
      width: 125
      defaultValue: ''
    ,
      field: 'data'
      displayName: 'Data'
      type: 'object'
      enableCellEdit: true
      editableCellTemplate: require('../../html/views/templates/jsonInput.jade')()
      width: 125
    ,
      field: 'retry_delay_seconds'
      displayName: 'Retry Delay'
      width: 125
    ,
      field: 'retry_max_count'
      displayName: 'Max Retries'
      width: 125
    ,
      field: 'hard_fail_timeouts'
      displayName: 'HF Timeout?'
      type: 'boolean'
      defaultValue: true
      width: 100
    ,
      field: 'hard_fail_after_retries'
      displayName: 'HF Retry?'
      type: 'boolean'
      defaultValue: true
      width: 100
    ,
      field: 'hard_fail_zombies'
      displayName: 'HF Zombie?'
      type: 'boolean'
      defaultValue: true
      width: 100
    ,
      field: 'warn_timeout_seconds'
      displayName: 'Warn TO sec'
      width: 125
    ,
      field: 'kill_timeout_seconds'
      displayName: 'Kill TO sec'
      width: 125
    ,
      field: 'auto_enqueue'
      displayName: 'Auto Enqueue?'
      type: 'boolean'
      defaultValue: true
      width: 125
  ]

  new rmapsGridFactory($scope)
