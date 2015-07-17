app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsQueueCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  $scope.jobsGrid =
    enableColumnMenus: false
    showColumnFooter: true
    columnDefs:[
    ]

  $scope.loadQueues = () ->
    $scope.jobsBusy = rmapsJobsService.getQueues()
    .then (queues) ->
      $scope.jobsGrid.data = queues.plain()

  $rootScope.registerScopeData () ->
    $scope.loadQueues()
