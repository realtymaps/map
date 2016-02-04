app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl',
($rootScope, $scope, $log, $window, $timeout, $document, $state, rmapsPrincipalService,
rmapsMailTemplateService, textAngularManager, rmapsMainOptions, rmapsMailTemplateTypeService) ->
  $log = $log.spawn 'frontend:mail:editTemplate'
  $log.debug 'editTemplate'

  editor = {}
  $scope.templObj = {}
  $scope.data =
    htmlcontent: ""

  setTemplObj = () ->
    $log.debug "Setting templObj.mailCampaign:\n#{JSON.stringify rmapsMailTemplateService.getCampaign()}"
    $scope.templObj =
      mailCampaign: rmapsMailTemplateService.getCampaign()

  $scope.quoteAndSend = () ->
    rmapsMailTemplateService.quote()

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
    rmapsMailTemplateService.setCampaign $scope.templObj.mailCampaign
    rmapsMailTemplateService.save()

  $scope.doPreview = () ->
    rmapsMailTemplateService.openPreview()

  $rootScope.registerScopeData () ->
    $scope.$parent.initMailTemplate()
    .then () ->
      setTemplObj()
      $scope.data =
        htmlcontent: $scope.templObj.mailCampaign.content
