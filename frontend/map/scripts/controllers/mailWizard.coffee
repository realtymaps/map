app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, rmapsprincipal, rmapsMailTemplate) ->
  $scope.step = $state.current.name

  $scope.property_ids = $state.params.property_ids

  $scope.steps = [
    'senderInfo'
    'selectTemplate'
    'editTemplate'
  ]

  _changeStep = (next = 1) ->
    rmapsMailTemplate.save()
    thisStep = $scope.steps.indexOf $scope.step
    newStep = $scope.steps[thisStep + next]
    if thisStep == -1 or !newStep? then return
    $state.go($state.get(newStep), {}, { reload: true })

  $scope.nextStep = () ->
    _changeStep(1)

  $scope.prevStep = () ->
    _changeStep(-1)

