app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsSubtaskCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  numericDefaults =
    aggregationType: uiGridConstants.aggregationTypes.sum
    type: 'number'
    width: 75
    cellClass: 'numberCell'
    footerCellTemplate: '<div class="numberCell">{{ col.getAggregationValue() }}</div>'

  dateFilter = 'date:"MM/dd HH:mm"'

  $scope.jobsGrid =
    enableColumnMenus: false
    onRegisterApi: (gridApi) ->
      gridApi.edit.on.afterCellEdit $scope, (rowEntity, colDef, newValue, oldValue) ->
        $scope.$apply()
        rowEntity.save()
    columnDefs:[
      field: 'name'
      displayName: 'Name'
      width: 100
    ,
      field: 'task_name'
      displayName: 'Task'
      width: 75
      enableCellEdit: false
    ,
      field: 'queue_name'
      displayName: 'Queue'
      width: 75
      enableCellEdit: false
    ,
      field: 'step_num'
      displayName: 'Step#'
      type: 'number'
      width: 75
    ,
      field: 'data'
      displayName: 'Data'
    ,
      field: 'retry_delay_seconds'
      displayName: 'Retry Delay'
    ,
      field: 'retry_max_count'
      displayName: 'Max Retries'
    ,
      field: 'hard_fail_timeouts'
      displayName: 'HF Timeout?'
    ,
      field: 'hard_fail_after_retries'
      displayName: 'HF Retry?'
    ,
      field: 'hard_fail_zombies'
      displayName: 'HF Zombie?'
    ,
      field: 'warn_timeout_seconds'
      displayName: 'Warn TO sec'
    ,
      field: 'kill_timeout_seconds'
      displayName: 'Kill TO sec'
    ,
      field: 'auto_enqueue'
      displayName: 'Auto Enqueue'
  ]

  $scope.loadSubtasks = () ->
    $scope.jobsBusy = rmapsJobsService.getSubtasks()
    .then (subtasks) ->
      $scope.jobsGrid.data = subtasks

  $rootScope.registerScopeData () ->
    $scope.loadSubtasks()
