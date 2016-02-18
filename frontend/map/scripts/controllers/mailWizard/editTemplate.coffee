app = require '../../app.coffee'
_ = require 'lodash'
modalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsEditTemplateCtrl',
($rootScope, $scope, $log, $window, $timeout, $document, $state, $modal, rmapsPrincipalService,
rmapsMailTemplateService, textAngularManager, rmapsMainOptions, rmapsMailTemplateTypeService) ->
  $log = $log.spawn 'mail:editTemplate'
  $log.debug 'editTemplate'

  editor = {}
  $scope.templObj = {}
  $scope.data =
    htmlcontent: ""

  $scope.saveButtonText =
    'saved': 'All Changes Saved'
    'saving': 'Saving...'
    'error': 'Error Saving'

  $scope.saveStatus = 'saved'

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

  $scope.saveContent = _.debounce () ->
    $scope.saveStatus = 'saving'
    $log.debug "saving #{$scope.templObj.name}"
    rmapsMailTemplateService.setCampaign $scope.templObj.mailCampaign
    rmapsMailTemplateService.save()
    .then ->
      $scope.saveStatus = 'saved'
    .catch ->
      $scope.saveStatus = 'error'
  , 1000

  $scope.$watch 'data.htmlcontent', $scope.saveContent

  $scope.animationsEnabled = true
  $scope.doPreview = () ->
    # rmapsMailTemplateService.openPreview()
    modalInstance = $modal.open
      animation: $scope.animationsEnabled
      template: modalTemplate
      controller: 'rmapsMailTemplatePdfPreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          content: $scope.data.htmlcontent
          category: rmapsMailTemplateService.getCategory()
          title: 'Mail Preview'

  $rootScope.registerScopeData () ->
    $scope.$parent.initMailTemplate()
    .then () ->
      setTemplObj()
      $scope.data =
        htmlcontent: $scope.templObj.mailCampaign.content
