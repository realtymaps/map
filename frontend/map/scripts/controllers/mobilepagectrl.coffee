app = require '../app.coffee'

module.exports = app.controller 'MobilePageCtrl', ($scope) ->
  $scope.isOn = false

  $scope.toggleIsOn = (event) ->
    event.stopPropagation() if event
    $scope.isOn = !$scope.isOn

  $scope.maybeToggleOn = (event) ->
    return if !$scope.isOn
    event.stopPropagation()
    $scope.isOn = false
