app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, rmapsprincipal, rmapsMailTemplate) ->
  $log = $log.spawn 'map:mailWizard'
  $log.debug 'rmapsMailWizardCtrl'

  $scope.step = $state.current.name

  $scope.mailTemplate = rmapsMailTemplate

  $scope.property_ids = $state.params.property_ids

  $scope.steps = [
    'recipientInfo'
    'senderInfo'
    'selectTemplate'
    'editTemplate'
  ]

  _changeStep = (next = 1) ->
    $scope.mailTemplate.save()
    thisStep = $scope.steps.indexOf $scope.step
    newStep = $scope.steps[thisStep + next]
    if thisStep == -1 or !newStep? then return
    $state.go($state.get(newStep), {}, { reload: true })

  $scope.nextStep = () ->
    _changeStep(1)

  $scope.prevStep = () ->
    _changeStep(-1)

