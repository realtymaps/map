mod = require '../module.coffee'

mod.controller 'rmapsModalInstanceCtrl', ($scope, $uibModalInstance, model) ->
  $scope.model = model

  $uibModalInstance.getScope = () ->
    $scope

  $scope.save = ->
    $uibModalInstance.close $scope.model

  $scope.cancel = ->
    $uibModalInstance.dismiss 'cancel'
