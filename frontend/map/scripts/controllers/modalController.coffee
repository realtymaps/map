app = require '../app.coffee'

app.controller 'rmapsModalInstanceCtrl', ($scope, $modalInstance, model) ->
  _.extend $scope,
    model: model

    save: ->
      $modalInstance.close $scope.model

    cancel: ->
      $modalInstance.dismiss 'cancel'
