app = require '../app.coffee'

module.exports = app

app.controller 'rmapsMailWizardCtrl', (
$rootScope
$scope
$log
$state
$location
$q
rmapsMailTemplateFactory
rmapsMailCampaignService) ->

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
    mail: null

  $scope.hideBackButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep == 0 or $scope.wizard.mail.isSubmitted())

  $scope.hideNextButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep == ($scope.steps.length - 1) or $scope.wizard.mail.isSubmitted())

  $scope.hideSendButton = () ->
    thisStep = _getStep $state.current.name
    (thisStep != ($scope.steps.length - 1) or $scope.wizard.mail.isSubmitted())

  $scope.hideProgress = () ->
    $scope.wizard.mail.isSubmitted()

  _getStep = (name) ->
    $scope.steps.indexOf name

  _changeStep = (next = 1) ->
    $scope.wizard.mail.save()
    .then (campaign) ->
      thisStep = _getStep $state.current.name
      newStep = $scope.steps[thisStep + next]
      if thisStep == -1 or !newStep? then return
      $log.debug "_changeStep() going to #{newStep}"
      $state.go($state.get(newStep), id: campaign.id)

  $scope.nextStep = (next = 1) ->
    _changeStep(next)

  $scope.prevStep = (next = -1) ->
    _changeStep(next)

  ensureValidState = () ->
    # if requesting state requiring template_type...
    if (_getStep($state.current.name) > 2 and !$scope.wizard.mail.campaign.template_type) or
    # or requesting state requiring content...
    (_getStep($state.current.name) > 3 and !$scope.wizard.mail.campaign.content)
      $state.go 'campaignInfo'
    # if explicitly requesting edit template for pdf campaign...
    else if $state.current.name == 'editTemplate' and !$scope.wizard.mail.campaign.custom_content
      $state.go 'review'

  if $state.params.id
    rmapsMailCampaignService.get id: $state.params.id
    .then ([campaign]) ->
      $scope.wizard.mail = new rmapsMailTemplateFactory(campaign)
      ensureValidState()
  else if $state.current.name == 'recipientInfo'
    $log.debug "Creating new mail campaign"
    $scope.wizard.mail = new rmapsMailTemplateFactory()
  else
    $state.go('mail')
