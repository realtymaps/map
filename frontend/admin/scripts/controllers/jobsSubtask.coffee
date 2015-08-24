app = require '../app.coffee'
GridController = require '../../../common/scripts/utils/gridController.coffee'

app.controller 'rmapsJobsSubtaskCtrl', ($scope, $rootScope, $injector, Restangular, rmapsJobsService) ->

  $scope.getData = rmapsJobsService.getSubtask

  @gridName = 'Subtask'

  @columnDefs = [
      field: 'name'
      displayName: 'Name'
      width: 200
      enableCellEdit: false
    ,
      field: 'task_name'
      displayName: 'Task'
      width: 125
      defaultValue: ''
    ,
      field: 'queue_name'
      displayName: 'Queue'
      width: 125
      defaultValue: ''
    ,
      field: 'step_num'
      displayName: 'Step#'
      type: 'number'
      width: 75
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

  $injector.invoke GridController, this,
    $scope: $scope
    $rootScope: $rootScope
    Restangular: Restangular
