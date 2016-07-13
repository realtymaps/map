app = require '../app.coffee'

app.controller 'rmapsModalInstanceCtrl', ($scope, $modalInstance, model) ->
  $scope.model = model

  $scope.save = ->
    $modalInstance.close $scope.model

  $scope.cancel = ->
    $modalInstance.dismiss 'cancel'
