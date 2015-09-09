app = require '../app.coffee'

app.controller 'rmapsTabsCtrl', ($scope, $window) ->
  $scope.active = t1: true

  $scope.setActiveTab = (tab) ->
    $scope.active = {}
    #reset
    $scope.active[tab] = true
