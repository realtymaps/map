app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsHistoryCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  numericDefaults =
    type: 'number'
    width: 75
    cellClass: 'numberCell'
    headerCellClass: 'numberCell'

  dateFilter = 'date:"MM/dd HH:mm"'

  $scope.jobsGrid =
    enableColumnMenus: false
    showColumnFooter: true
    columnDefs:[
      field: 'name'
      displayName: 'Task'
      width: 100
      footerCellTemplate: '<div>Totals</div>'
    ,
      field: 'status'
      displayName: 'Status'
      width: 75
    ,
      field: 'batch_id'
      displayName: 'Batch'
      width: 75
    ,
      field: 'started'
      displayName: 'Subtasks'
      type: 'date'
      width: 100
      cellFilter: dateFilter
      sort:
        direction: uiGridConstants.DESC
    ,
      field: 'finished'
      displayName: 'Finished'
      type: 'date'
      width: 75,
      cellFilter: dateFilter
      visible: false
    ,
      field: 'status_changed'
      displayName: 'Changed'
      type: 'date'
      width: 100
      cellFilter: dateFilter
    ,
      field: 'initiator'
      displayName: 'Initiator'
      width: 75
    ,
      field: 'data'
      displayName: 'Data'
      visible: false
  ].concat _.map [
      field: 'subtasks_created'
      displayName: 'Created'
    ,
      field: 'subtasks_preparing'
      displayName: 'Prep'
    ,
      field: 'subtasks_running'
      displayName: 'Running'
    ,
      field: 'subtasks_succeeded'
      displayName: 'Success'
    ,
      field: 'subtasks_failed'
      displayName: 'Failed'
    ,
      field: 'subtasks_soft_failed'
      displayName: 'S Fail'
    ,
      field: 'subtasks_hard_failed'
      displayName: 'H Fail'
    ,
      field: 'subtasks_infrastructure_failed'
      displayName: 'I Fail'
    ,
      field: 'subtasks_canceled'
      displayName: 'Cancel'
    ,
      field: 'subtasks_timeout'
      displayName: 'TimeOut'
    ,
      field: 'subtasks_zombie'
      displayName: 'Zombie'
    ,
      field: 'warn_timeout_minutes'
      displayName: 'Warn TO'
      visible: false
    ,
      field: 'kill_timeout_minutes'
      displayName: 'Kill TO'
      visible: false
    ], (num) ->
      _.extend num, numericDefaults

  $scope.selectTask = () ->
    $scope.loadHistory($state.params.task)

  $scope.loadHistory = (task) ->
    $scope.jobsBusy = rmapsJobsService.getHistory(task)
    .then (history) ->
      $scope.jobsGrid.data = history.plain()

  $rootScope.registerScopeData () ->
    if $state.params.task
      $scope.loadHistory($state.params.task)
