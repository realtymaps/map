app = require '../../app.coffee'
_ = require 'lodash'
modalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsEditTemplateCtrl',
($rootScope, $scope, $log, $modal, rmapsPrincipalService, textAngularManager, rmapsMainOptions) ->
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
    $scope.wizard.mail.dirty = true
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
    $modal.open
      animation: $scope.animationsEnabled
      template: modalTemplate
      controller: 'rmapsMailTemplatePdfPreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          title: 'Mail Preview'
          pdfPromise: $scope.wizard.mail.getQuoteAndPdf()

  $scope.quoteAndSend = () ->
    $scope.wizard.mail.save()
    .then () ->
      $modal.open
        template: require('../../../html/views/templates/modal-snailPrice.tpl.jade')()
        controller: 'rmapsModalSnailPriceCtrl'
        keyboard: false
        backdrop: 'static'
        windowClass: 'snail-modal'
        resolve:
          template: () ->
            campaign: $scope.wizard.mail.campaign
