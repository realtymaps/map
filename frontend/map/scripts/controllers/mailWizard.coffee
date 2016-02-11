util = require 'util'
app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, $q, $modal, rmapsMailTemplateService, rmapsLobService) ->
  $log = $log.spawn 'mail:mailWizard'
  $log.debug 'rmapsMailWizardCtrl'
  $scope.steps = [
    'recipientInfo'
    'senderInfo'
    'selectTemplate'
    'editTemplate'
    'review'
  ]

  $scope.hideBackButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep == 0 or rmapsMailTemplateService.isSent())

  $scope.hideNextButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep == $scope.steps.length-1 or rmapsMailTemplateService.isSent())

  $scope.hideSendButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep != $scope.steps.length-1 or rmapsMailTemplateService.isSent())

  $scope.hideProgress = () ->
    rmapsMailTemplateService.isSent()

  _getStep = (name) ->
    $scope.steps.indexOf name

  _changeStep = (next = 1) ->
    rmapsMailTemplateService.save()
    thisStep = _getStep $state.current.name
    newStep = $scope.steps[thisStep + next]
    if thisStep == -1 or !newStep? then return
    $log.debug "_changeStep() going to #{newStep}"
    $state.go($state.get(newStep))

  $scope.nextStep = () ->
    _changeStep(1)

  $scope.prevStep = () ->
    _changeStep(-1)

  # accessed in child controllers for maintaining mailTemplate object
  $scope.initMailTemplate = () ->
    if $state.params.id
      $log.debug "Loading mail campaign #{$state.params.id}"
      return rmapsMailTemplateService.load $state.params.id
    else
      campaign = rmapsMailTemplateService.getCampaign()
      $log.debug "Continuing with mail campaign #{campaign.id}"
      return $q.when campaign
