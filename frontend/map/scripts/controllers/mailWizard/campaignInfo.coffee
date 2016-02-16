app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsCampaignInfoCtrl', ($rootScope, $scope, rmapsUsStatesService, rmapsMailTemplateService) ->
  $scope.us_states = []

  $rootScope.registerScopeData () ->
    $scope.$parent.initMailTemplate()
    .then () ->
      rmapsMailTemplateService.getSenderData()
      .then (senderData) ->
        $scope.senderData = senderData
        $scope.campaign = rmapsMailTemplateService.getCampaign()

      rmapsUsStatesService.getAll().then (states) ->
        $scope.us_states = states
