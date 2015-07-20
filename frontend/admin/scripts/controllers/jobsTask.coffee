app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsTaskCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  numericDefaults =
    type: 'number'
    width: 100
    cellClass: 'numberCell'
    headerCellClass: 'numberCell'

  dateFilter = 'date:"MM/dd HH:mm"'

  $scope.jobsGrid =
    enableColumnMenus: false
    onRegisterApi: (gridApi) ->
      gridApi.edit.on.afterCellEdit $scope, (rowEntity, colDef, newValue, oldValue) ->
        $scope.$apply()
        rowEntity.save()
    columnDefs:[
      field: 'name'
      displayName: 'Task'
      width: 100
    ,
      field: 'description'
      displayName: 'Description'
      width: 300
    ,
      field: 'data'
      displayName: 'Data'
      width: 200
    ,
      field: 'ignore_until'
      displayName: 'Ignore Until'
      type: 'date'
      width: 100
      cellFilter: dateFilter
  ].concat _.map [
      field: 'repeat_period_minutes'
      displayName: 'Repeat Minutes'
      width: 100
    ,
      field: 'warn_timeout_minutes'
      displayName: 'Warn TO'
    ,
      field: 'kill_timeout_minutes'
      displayName: 'Kill TO'
    ], (num) ->
      _.extend num, numericDefaults

  $scope.loadTasks = () ->
    $scope.jobsBusy = rmapsJobsService.getTasks()
    .then (tasks) ->
      _.each tasks, (task) ->
        task.ignore_until = new Date(task.ignore_until)
      $scope.jobsGrid.data = tasks

  $rootScope.registerScopeData () ->
    $scope.loadTasks()
