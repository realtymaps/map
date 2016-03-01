util = require 'util'
app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, $location, $q, rmapsMailTemplateFactory) ->
  $log = $log.spawn 'mail:mailWizard'
  $log.debug 'rmapsMailWizardCtrl'
  $scope.steps = [
    'recipientInfo'
    'campaignInfo'
    'selectTemplate'
    'editTemplate'
    'review'
  ]

  $scope.wizard =
    mail: new rmapsMailTemplateFactory()

  $scope.hideBackButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep == 0 or $scope.wizard.mail.isSent())

  $scope.hideNextButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep == ($scope.steps.length - 1) or $scope.wizard.mail.isSent())

  $scope.hideSendButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep != ($scope.steps.length - 1) or $scope.wizard.mail.isSent())

  $scope.hideProgress = () ->
    $scope.wizard.mail.isSent()

  _getStep = (name) ->
    $scope.steps.indexOf name

  _changeStep = (next = 1) ->
    $scope.wizard.mail.save()
    .then (campaign) ->
      $location.search 'id', campaign.id
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
  $scope.ready = () ->
    if $state.params.id
      $log.debug "Loading mail campaign #{$state.params.id}"
      return $scope.wizard.mail.load $state.params.id # return promise
    else
      if $state.current.name != 'recipientInfo' and !$scope.wizard.mail.campaign.id?
        $state.go('mail') # redirect
      else
        $log.debug "Continuing with mail campaign #{$scope.wizard.mail.campaign.id}"
        return $q.when $scope.wizard.mail.campaign # return promise
