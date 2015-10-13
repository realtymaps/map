app = require '../../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsHistoryCtrl',
($window, $scope, $rootScope, $log, rmapsJobsService, uiGridConstants, $state) ->

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

  $scope.updateTimeframe = () ->
    if $scope.currentTaskData.task?
      $scope.jobsGrid.data = []
      $scope.currentTaskData.task = null
    $scope.getHistoryList()

  $scope.selectJob = () ->
    $log.debug "#### selectJob(), currentTaskData"
    $log.debug $scope.currentTaskData
    $state.go($state.current, { task: $scope.currentTaskData.task.name }, { reload: true })

  $scope.loadHistory = (task) ->
    $log.debug "#### loadHistory(), task:"
    $log.debug task
    filters =
      timerange: $scope.historyTimerange
    if task.name == 'all'
      filters['current'] = true
    else
      filters['name'] = task.name
    $scope.jobsBusy = rmapsJobsService.getHistory(filters)
    .then (history) ->
      $scope.jobsGrid.data = history.plain()

  $scope.getHistoryList = () ->
    filters =
      list: true
      timerange: $scope.historyTimerange
    $scope.jobsBusy = rmapsJobsService.getHistory(filters)
    .then (currentJobList) ->
      $scope.currentJobList = [{name: 'All', current: 'all'}].concat currentJobList.plain()
      $log.debug "#### tasklist:"
      $log.debug $scope.currentJobList

  $scope.loadReadyHistory = () ->
    $scope.getHistoryList()
    .then () ->
      $log.debug "#### $state.params:"
      $log.debug $state.params
      if $state.params.task
        $scope.currentTaskData.task = _.find $scope.currentJobList, { task: $state.params.task }
        $scope.loadHistory($state.params.task)

  $rootScope.registerScopeData () ->
    $scope.loadReadyHistory()
