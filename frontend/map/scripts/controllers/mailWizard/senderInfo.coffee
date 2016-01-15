app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSenderInfoCtrl', ($rootScope, $scope, $log, rmapsUsStates) ->
  $scope.us_states = []

  $rootScope.registerScopeData () ->
    $scope.mailTemplate.procureSenderData()

    rmapsUsStates.getAll().then (states) ->
      $scope.us_states = states
