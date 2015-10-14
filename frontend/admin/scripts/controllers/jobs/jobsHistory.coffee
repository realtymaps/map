app = require '../../app.coffee'
_ = require 'lodash'
Promise = require 'bluebird'

app.controller 'rmapsJobsHistoryCtrl',
($window, $scope, $rootScope, $log, $location, rmapsJobsService, uiGridConstants, $state) ->
  $scope.currentTaskData =
    task: null

  $scope.currentJobList = []

  $scope.historyTimerange = '30 days'

  numericDefaults =
    type: 'number'
    width: 75
    cellClass: 'numberCell'

  dateFilter = 'date:"MM/dd HH:mm"'

  $scope.jobsGrid =
    enableColumnMenus: false
    enablePinning: true
    columnDefs: [
      field: 'name'
      displayName: 'Task'
      width: 100
      pinnedLeft: true
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
      displayName: 'Started'
      type: 'date'
      width: 100
      cellFilter: dateFilter
      sort:
        direction: uiGridConstants.DESC
    ,
      field: 'finished'
      displayName: 'Finished'
      type: 'date'
      width: 100,
      cellFilter: dateFilter
      visible: true
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

  $scope.jobsErrorGrid =
    enableColumnMenus: false
    enablePinning: true
    enableCellEditOnFocus: true
    columnDefs: [
      field: 'task_name'
      displayName: 'Task'
      width: 100
      pinnedLeft: true
      enableCellEdit: false
    ,
      field: 'name'
      displayName: 'Subtask'
      width: 150
      pinnedLeft: true
      enableCellEdit: false
    ,
      field: 'status'
      displayName: 'Status'
      width: 75
      enableCellEdit: false
    ,
      field: 'retry_num'
      displayName: 'Retries'
      width: 75
      enableCellEdit: false
    ,
      field: 'batch_id'
      displayName: 'Batch'
      width: 75
      enableCellEdit: false
    ,
      field: 'started'
      displayName: 'Started'
      type: 'date'
      width: 100
      cellFilter: dateFilter
      enableCellEdit: false
    ,
      field: 'finished'
      displayName: 'Finished'
      type: 'date'
      width: 100,
      cellFilter: dateFilter
      enableCellEdit: false
    ,
      field: 'data'
      displayName: 'Data'
      cellTemplate: '<div class="ui-grid-cell-contents">{{COL_FIELD | json}}</div>'
      enableCellEdit: false
    ,
      field: 'error'
      displayName: 'error'
    ,
      field: 'stack'
      displayName: 'Stack'
    ]

  $scope.tooltip = (mouseEvent) ->
    console.log mouseEvent

  $scope.updateTimeframe = () ->
    if $scope.currentTaskData.task?
      $scope.jobsGrid.data = []
      $scope.jobsErrorGrid.data = []
      $scope.currentTaskData.task = null
    if $state.params.timerange # don't honor timerange parameter anymore
      delete $state.params.timerange
    $scope.loadReadyHistory()

  $scope.selectJob = () ->
    $state.go($state.current, { task: $scope.currentTaskData.task.name, current: $scope.currentTaskData.task.current, timerange: $scope.historyTimerange }, { reload: true })

  $scope.loadHistory = (task) ->
    filters =
      timerange: $scope.historyTimerange
    errorFilters = _.clone filters
    filters.current = task.current
    if task.name != 'all'
      filters.name = errorFilters.task_name = task.name
      
    $scope.jobsBusy = rmapsJobsService.getHistory(filters)
    .then (history, errorHistory) ->
      $scope.jobsGrid.data = history.plain()

    $scope.errorJobsBusy = rmapsJobsService.getSubtaskErrorHistory(errorFilters)
    .then (errorHistory) ->
      $scope.jobsErrorGrid.data = errorHistory.plain()

  $scope.getHistoryList = () ->
    filters =
      list: true
      timerange: $scope.historyTimerange
    $scope.jobsBusy = rmapsJobsService.getHistory(filters)
    .then (currentJobList) ->
      $scope.currentJobList = [{name: 'All', current: false}].concat currentJobList.plain()
      for e, i in $scope.currentJobList
        $scope.currentJobList[i].selectid = i

  $scope.loadReadyHistory = () ->
    $scope.getHistoryList()
    .then () ->
      if $state.params.timerange
        $scope.historyTimerange = $state.params.timerange
      if $state.params.task and $state.params.current
        $scope.currentTaskData.task = _.find $scope.currentJobList, { name: $state.params.task, current: $state.params.current=='true' }
        if $scope.currentTaskData.task? # load history only if it's in our currentJobList dropdown (wouldn't have history entries for given filters)
          $scope.loadHistory($scope.currentTaskData.task)
        else # account for a certain case where a previous search was done, but new timerange selected that invalidates it since dropdown is refreshed, but $state.params remain
          $state.params = {}

  $rootScope.registerScopeData () ->
    $scope.loadReadyHistory()
