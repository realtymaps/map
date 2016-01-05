app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl',
($rootScope, $scope, $log, $window, $timeout, $document, $state, rmapsprincipal,
rmapsMailTemplate, textAngularManager, rmapsMainOptions, rmapsMailTemplateTypeService) ->

  editor = {}

  $scope.templObj = rmapsMailTemplate

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
    htmlcontent: rmapsMailTemplate.getContent()

  $scope.doPreview = () ->
    rmapsMailTemplate.openPreview()
