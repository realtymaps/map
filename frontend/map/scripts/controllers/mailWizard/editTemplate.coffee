app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl',
($rootScope, $scope, $log, $window, $timeout, $document, $state, rmapsPrincipalService,
rmapsMailTemplateService, textAngularManager, rmapsMainOptions, rmapsMailTemplateTypeService) ->

  editor = {}

  $scope.templObj = rmapsMailTemplateService

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
    rmapsMailTemplateService.save()

  $scope.data =
    htmlcontent: rmapsMailTemplateService.getContent()

  $scope.doPreview = () ->
    rmapsMailTemplateService.openPreview()
