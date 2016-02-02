util = require 'util'
app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, rmapsMailTemplateService) ->
  $log = $log.spawn 'mail:mail:mailWizard'
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
    rmapsMailTemplateService.save()
    thisStep = _getStep $state.current.name
    newStep = $scope.steps[thisStep + next]
    if thisStep == -1 or !newStep? then return
    $state.go($state.get(newStep))

  $scope.nextStep = () ->
    _changeStep(1)

  $scope.prevStep = () ->
    _changeStep(-1)

  $rootScope.registerScopeData () ->
    step = _getStep($state.current.name)
    $log.debug "state.current.name: #{$state.current.name}"
    $log.debug "intended wizard step: #{step}"
    $log.debug "getCampaign().id:  #{rmapsMailTemplateService.getCampaign().id}"

    # if getting a param.id, load it and goto senderInfo
    if $state.params.id
      rmapsMailTemplateService.load($state.params.id)
      .then () ->
        $log.debug "$state.go 'senderInfo'..."
        $state.go 'senderInfo'

    # send user straight to mail list page if trying to make invalid req to wizard step
    else if step != 0 and not rmapsMailTemplateService.getCampaign().id
      $state.go 'mail', {}, {reload: true}
