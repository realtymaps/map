app = require '../app.coffee'

app.controller 'rmapsAccordionCtrl', ($scope) ->
  $scope.oneAtATime = true
  $scope.status =
    isItemOpen: new Array
    isFirstDisabled: false
  $scope.status.isItemOpen[0] = true
