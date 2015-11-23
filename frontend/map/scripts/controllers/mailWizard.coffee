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


  $scope.nextStep = () ->
    thisStep = $scope.steps.indexOf $scope.step
    if thisStep >= ($scope.steps.length-1)
      return
    newStep = $scope.steps[thisStep+1]
    $state.go($state.get(newStep), {}, { reload: true })

  $scope.prevStep = () ->
    thisStep = $scope.steps.indexOf $scope.step
    if thisStep <= 0
      return
    newStep = $scope.steps[thisStep-1]
    $state.go($state.get(newStep), {}, { reload: true })
