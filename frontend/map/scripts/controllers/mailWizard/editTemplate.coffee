app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl',
($rootScope, $scope, $log, $window, $timeout, $document, $state, rmapsprincipal,
rmapsMailTemplate, textAngularManager, rmapsMainOptions, rmapsMailTemplateTypeService) ->

  # # may as well set up a templateType choice just in case it's not set for some reason
  # typeNames = rmapsMailTemplateTypeService.getTypeNames()
  # if $state.params.templateType? and $state.params.templateType in typeNames
  #   $scope.templateType = $state.params.templateType
  # else
  #   $scope.templateType = typeNames[0]

  # $scope.templateObj = new rmapsMailTemplate($scope.templateType)

  editor = {}

  # $log.debug "(editctrl) superTemplateObj:"
  # $log.debug rmapsMailTemplate.oid

  $scope.templObj = rmapsMailTemplate

  $log.debug "(editTemplate) templObj:"
  $log.debug $scope.templObj


  $scope.quoteAndSend = () ->
    rmapsMailTemplate.quote()

  $scope.textEditorSetup = () ->
    (el) ->
      $log.debug "#### textEditorSetup operation, el:"
      $log.debug el

  $scope.htmlEditorSetup = () ->
    (el) ->
      $log.debug "#### htmlEditorSetup operation, el:"
      $log.debug el

  $scope.macros =
    rmapsMainOptions.mail.macros

  $scope.macro = ""

  $scope.saveContent = () ->
    rmapsMailTemplate.save()

  $scope.data =
    #htmlcontent: $scope.templateObj.mailCampaign.content
    htmlcontent: rmapsMailTemplate.getContent()

  # $scope.applyTemplateClass = (qualifier = '') ->
  #   "#{$scope.templateType}#{qualifier}"

  $scope.doPreview = () ->
    rmapsMailTemplate.openPreview()
