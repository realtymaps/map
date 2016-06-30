app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsCampaignInfoCtrl', ($rootScope, $scope, $log, $validation, rmapsUsStates) ->

  $log = $log.spawn 'frontend:mail:campaignInfo'
  $scope.us_states = rmapsUsStates.all

  $scope.form =
    checkValid: $validation.checkValid
    submit: ->
      $log.debug 'campaign info valid'

  $scope.wizard.mail.getSenderData()
  .then (senderData) ->
    $scope.senderData = senderData
