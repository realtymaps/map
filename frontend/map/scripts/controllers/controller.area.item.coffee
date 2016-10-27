app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsAreaItemCtrl', ($scope, $q) ->

  cloneModel = null

  $scope.rename = (model) ->
    cloneModel = _.cloneDeep model
    $scope.deferRename = $q.defer()
    $scope.isRenaming = true

    $scope.deferRename.promise
    .then (doSubmit) ->
      if doSubmit
        $scope.signalUpdate($scope.drawnShapesSvc.update(model))
        .then ->
          $scope.isRenaming = false

      $q.resolve $scope.isRenaming = false

  $scope.cancel = (model) ->
    _.extend model, cloneModel #revert
    $scope.deferRename?.resolve(false)

  $scope.save = () ->
    $scope.deferRename?.resolve(true)
