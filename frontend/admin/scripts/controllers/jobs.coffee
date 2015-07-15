app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsCtrl',
($window, $scope, $rootScope, rmapsJobsService) ->

  $scope.jobsGrid =
    columnDefs = []

  # Load Job status info
  $rootScope.registerScopeData () ->
    rmapsJobsService.getAll()
    .then (jobs) ->
      $scope.jobsGrid.data = jobs.plain()
      _.each $scope.jobsGrid.data?[0], (v, col) ->
        unless col == 'data'
          $scope.jobsGrid.columnDefs.push field: col
