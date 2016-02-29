app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsCampaignInfoCtrl', ($rootScope, $scope, $log, $validation, rmapsUsStatesService) ->

  $log = $log.spawn 'frontend:mail:campaignInfo'
  $scope.us_states = []

  $log.debug $validation.checkValid
  $scope.form =
    checkValid: $validation.checkValid
    submit: ->
      $log.debug 'campaign info valid'

  $rootScope.registerScopeData () ->
    $scope.ready()
    .then () ->
      $scope.wizard.mail.getSenderData()
      .then (senderData) ->
        $scope.senderData = senderData

      rmapsUsStatesService.getAll().then (states) ->
        $scope.us_states = states
