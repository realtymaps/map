app = require '../../app.coffee'
_ = require 'lodash'
modalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsEditTemplateCtrl',
($rootScope, $scope, $log, $uibModal, $timeout, rmapsPrincipalService, rmapsMainOptions) ->
  $log = $log.spawn 'mail:editTemplate'
  $log.debug 'editTemplate'

  editor = {}

  $scope.saveButtonText =
    'saved': 'All Changes Saved'
    'saving': 'Saving...'
    'error': 'Error Saving'

  $scope.saveStatus = 'saved'

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
    $log.debug "saving #{$scope.wizard.mail.campaign.name}"
    # content changed, we'll need to remake the pdf and aws_key
    # (pdf isn't made until the review-preview call on review page)
    $scope.wizard.mail.campaign.aws_key = null
    $scope.wizard.mail.setDirty()
    $scope.wizard.mail.save()
    .then ->
      $scope.saveStatus = 'saved'
    .catch ->
      $scope.saveStatus = 'error'
  , 1000

  $scope.$watch 'wizard.mail.campaign.content', (newVal, oldVal) ->
    if oldVal != newVal
      $scope.saveContent()

  $scope.animationsEnabled = true

  $scope.doPreview = () ->
    $uibModal.open
      animation: $scope.animationsEnabled
      template: modalTemplate
      controller: 'rmapsMailTemplatePdfPreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          title: 'Mail Preview'
          pdfPromise: $scope.wizard.mail.getReviewDetails()
