app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsCampaignInfoCtrl', ($rootScope, $scope, rmapsUsStatesService) ->
  $scope.us_states = []

  $rootScope.registerScopeData () ->
    $scope.ready()
    .then () ->
      $scope.wizard.mail.getSenderData()
      .then (senderData) ->
        $scope.senderData = senderData

      rmapsUsStatesService.getAll().then (states) ->
        $scope.us_states = states
