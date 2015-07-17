app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsTaskCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  $scope.jobsGrid =
    enableColumnMenus: false
    showColumnFooter: true
    columnDefs:[
    ]

  $scope.loadTask = () ->
    $scope.jobsBusy = rmapsJobsService.getTasks()
    .then (tasks) ->
      $scope.jobsGrid.data = tasks.plain()

  $rootScope.registerScopeData () ->
    $scope.loadTasks()
