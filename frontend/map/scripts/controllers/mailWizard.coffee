app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, rmapsprincipal) ->
  $log.debug "#### state:"
  $log.debug $state
  $scope.step = $state.current.name

  $scope.steps = [
    'selectTemplate'
    'editTemplate'
  ]

  _changeStep = (next = 1) ->
    thisStep = $scope.steps.indexOf $scope.step
    newStep = $scope.steps[thisStep + next]
    if thisStep == -1 or !newStep? then return
    $state.go($state.get(newStep), {}, { reload: true })

  $scope.nextStep = () ->
    _changeStep(1)

  $scope.prevStep = () ->
    _changeStep(-1)
