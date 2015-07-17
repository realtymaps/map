app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsHistoryCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  $scope.jobsGrid =
    enableColumnMenus: false
    showColumnFooter: true
    columnDefs:[
    ]

  $scope.loadHistory = () ->
    $scope.jobsBusy = rmapsJobsService.getHistory($state.params.name)
    .then (history) ->
      $scope.jobsGrid.data = history.plain()

  $rootScope.registerScopeData () ->
    $scope.loadHistory()
