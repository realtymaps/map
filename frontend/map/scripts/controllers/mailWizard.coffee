util = require 'util'
app = require '../app.coffee'
_ = require 'lodash'

module.exports = app


app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, $q, rmapsMailTemplate) ->
  $log = $log.spawn 'frontend:mail:mailWizard'
  $log.debug 'rmapsMailWizardCtrl'
  $scope.steps = [
    'recipientInfo'
    'senderInfo'
    'selectTemplate'
    'editTemplate'
  ]

  _getStep = (name) ->
    $scope.steps.indexOf name

  _changeStep = (next = 1) ->
    rmapsMailTemplate.save()
    thisStep = _getStep $state.current.name
    newStep = $scope.steps[thisStep + next]
    if thisStep == -1 or !newStep? then return
    $state.go($state.get(newStep))

  $scope.nextStep = () ->
    _changeStep(1)

  $scope.prevStep = () ->
    _changeStep(-1)


  $scope.initMailTemplate = () ->
    if $state.params.id
      $log.debug "Loading mail campaign #{$state.params.id}"
      rmapsMailTemplate.load $state.params.id
    else
      campaign = rmapsMailTemplate.getCampaign()
      $log.debug "Continuing with mail campaign #{campaign.id}"
      $q.when campaign

  # $rootScope.registerScopeData () ->
  #   step = _getStep($state.current.name)
  #   $log.debug "state.current.name: #{$state.current.name}"
  #   $log.debug "intended wizard step: #{step}"
  #   $log.debug "getCampaign().id:  #{rmapsMailTemplate.getCampaign().id}"

  #   # if getting a param.id, load it and goto senderInfo
  #   if $state.params.id
  #     rmapsMailTemplate.load($state.params.id)
  #     .then () ->
  #       $log.debug "$state.go 'senderInfo'..."
  #       $state.go 'senderInfo'

  #   # send user straight to mail list page if trying to make invalid req to wizard step
  #   else if step != 0 and not rmapsMailTemplate.getCampaign().id
  #     $state.go 'mail', {}, {reload: true}

