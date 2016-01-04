app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSenderInfoCtrl', ($rootScope, $scope, $state, $log, $timeout, rmapsprincipal, rmapsGeoLocations, rmapsMailTemplate) ->
  $scope.us_states = []

  $scope.templObj = rmapsMailTemplate

  $rootScope.registerScopeData () ->
    rmapsMailTemplate.procureSenderData()
    .then (senderData) ->
      $scope.templObj.senderData = senderData
      rmapsGeoLocations.states().then (states) ->
        $scope.us_states = states
