app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSenderInfoCtrl', ($rootScope, $scope, rmapsUsStates, rmapsMailTemplate) ->
  $scope.us_states = []

  $rootScope.registerScopeData () ->
    $scope.$parent.initMailTemplate()
    .then () ->
      rmapsMailTemplate.getSenderData()
      .then (senderData) ->
        $scope.senderData = senderData

      rmapsUsStates.getAll().then (states) ->
        $scope.us_states = states
