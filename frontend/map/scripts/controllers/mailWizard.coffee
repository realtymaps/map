app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, rmapsMailTemplate) ->
  $log = $log.spawn 'frontend:map:mailWizard'
  $log.debug 'rmapsMailWizardCtrl'

  $scope.steps = [
    'recipientInfo'
    'senderInfo'
    'selectTemplate'
    'editTemplate'
  ]

  _changeStep = (next = 1) ->
    rmapsMailTemplate.save()
    thisStep = $scope.steps.indexOf $state.current.name
    newStep = $scope.steps[thisStep + next]
    if thisStep == -1 or !newStep? then return
    $state.go($state.get(newStep))

  $scope.nextStep = () ->
    _changeStep(1)

  $scope.prevStep = () ->
    _changeStep(-1)


  # $rootScope.registerScopeData () ->
  #   if $state.params.id
  #     rmapsMailTemplate.load($state.params.id)
  #     .then () ->
  #       $state.go 'senderInfo'
  #   else
  #     $state.go 'mail', reload: true
