app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSenderInfoCtrl', ($rootScope, $scope, rmapsUsStates, rmapsMailTemplate) ->
  $scope.us_states = []

  $scope.senderData = rmapsMailTemplate.getSenderData()

  $rootScope.registerScopeData () ->
    rmapsMailTemplate.procureSenderData()

    rmapsUsStates.getAll().then (states) ->
      $scope.us_states = states
