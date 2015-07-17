app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsSubtaskCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  $scope.jobsGrid =
    enableColumnMenus: false
    showColumnFooter: true
    columnDefs:[
    ]

  $scope.loadSubtask = () ->
    $scope.jobsBusy = rmapsJobsService.getSubtasks()
    .then (subtasks) ->
      $scope.jobsGrid.data = subtasks.plain()

  $rootScope.registerScopeData () ->
    $scope.loadSubtasks()
