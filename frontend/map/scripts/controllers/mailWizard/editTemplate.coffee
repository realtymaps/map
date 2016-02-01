app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl',
($rootScope, $scope, $log, $window, $timeout, $document, $state, rmapsprincipal,
rmapsMailTemplate, textAngularManager, rmapsMainOptions, rmapsMailTemplateTypeService) ->
  $log = $log.spawn 'frontend:mail:editTemplate'
  $log.debug 'editTemplate'

  editor = {}

  $scope.templObj = {}
  setTemplObj = () ->
    $log.debug "Setting templObj.mailCampaign:\n#{JSON.stringify rmapsMailTemplate.getCampaign()}"
    $scope.templObj =
      mailCampaign: rmapsMailTemplate.getCampaign()

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
    $log.debug "saving #{$scope.templObj.name}"
    rmapsMailTemplate.mailCampaign = $scope.templObj.mailCampaign
    rmapsMailTemplate.save()

  $scope.data =
    htmlcontent: rmapsMailTemplate.getContent()

  $scope.doPreview = () ->
    rmapsMailTemplate.openPreview()

  $rootScope.registerScopeData () ->
    $scope.$parent.initMailTemplate()
    .then () ->
      setTemplObj()
