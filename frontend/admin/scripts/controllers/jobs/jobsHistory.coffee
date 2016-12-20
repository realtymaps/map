app = require '../../app.coffee'
_ = require 'lodash'


app.controller 'rmapsJobsHistoryCtrl',
($window, $scope, $rootScope, $log, $location, rmapsJobsService, uiGridConstants, $state) ->
  $scope.currentTaskData =
    task: null

  $scope.currentJobList = []
  $scope.historyTimerange = '30 days'
  $scope.clickedCellInfo = null

  numericDefaults =
    type: 'number'
    width: 75
    cellClass: 'numberCell'

  dateFilter = 'date:"MM/dd HH:mm"'

  $scope.jobsGrid =
    enableFiltering: true
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
    enableFiltering: true
    enableColumnMenus: false
    enablePinning: true
    appScopeProvider: $scope
    onRegisterApi: (gridApi) ->
      gridApi.cellNav.on.navigate $scope, (newRowCol, oldRowCol) ->
        $scope.showFullCellContents(newRowCol)
    columnDefs: [
      field: 'task_name'
      displayName: 'Task'
      width: 100
      pinnedLeft: true
    ,
      field: 'name'
      displayName: 'Subtask'
      width: 150
      pinnedLeft: true
    ,
      field: 'status'
      displayName: 'Status'
      width: 75
    ,
      field: 'retry_num'
      displayName: 'Retries'
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
    ,
      field: 'data'
      displayName: 'Data'
      cellTemplate: '<div class="ui-grid-cell-contents clickable-cell">{{COL_FIELD | json}}</div>'
    ,
      field: 'error'
      displayName: 'Error'
      cellClass: 'clickable-cell'
    ,
      field: 'stack'
      displayName: 'Stack'
      cellClass: 'clickable-cell'
    ]

  $scope.showFullCellContents = (rowCol) ->
    if !rowCol? || rowCol.col.colDef.displayName not in ['Data', 'Error', 'Stack']
      $scope.clickedCellInfo = null
      return
    $scope.clickedCellInfo =
      name: rowCol.col.colDef.displayName
      contents: rowCol.row.entity[rowCol.col.colDef.name]
    if $scope.clickedCellInfo.name == 'Data'
      $scope.clickedCellInfo.contents = JSON.stringify($scope.clickedCellInfo.contents, null, 2)

  $scope.updateTimeframe = () ->
    if $scope.currentTaskData.task?
      $scope.selectJob()
    if $state.params.timerange # don't honor timerange parameter anymore
      delete $state.params.timerange
    $scope.loadReadyHistory()

  $scope.selectJob = () ->
    filters =
      timerange: $scope.historyTimerange
      task: $scope.currentTaskData.task.name
    $state.go($state.current, filters, { reload: true })

  $scope.loadHistory = (task) ->
    filters =
      timerange: $scope.historyTimerange
    errorFilters = _.clone filters
    if task.name != 'All Tasks'
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
      $scope.currentJobList = [{name: 'All Tasks'}].concat currentJobList.plain()
      # coffeelint: disable=check_scope
      for e, i in $scope.currentJobList
      # coffeelint: enable=check_scope
        $scope.currentJobList[i].selectid = i

  $scope.loadReadyHistory = () ->
    $scope.getHistoryList()
    .then () ->
      if $state.params.timerange
        $scope.historyTimerange = $state.params.timerange
      if $state.params.task
        $scope.currentTaskData.task = _.find $scope.currentJobList, { name: $state.params.task }
        if $scope.currentTaskData.task? # load history only if it's in our currentJobList dropdown (wouldn't have history entries for given filters)
          $scope.loadHistory($scope.currentTaskData.task)
        else # account for a certain case where a previous search was done, but new timerange selected that invalidates it since dropdown is refreshed, but $state.params remain
          $state.params = {}

  $scope.loadReadyHistory()
