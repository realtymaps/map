app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl', ($rootScope, $scope, $log, $window, $timeout, $document, rmapsprincipal, rmapsMailTemplate, textAngularManager, rmapsMainOptions) ->

  # might move this object to the mailWizard (parent) scope to expose the members to all wizard steps for building the object
  $scope.templateObj = new rmapsMailTemplate($scope.$parent.templateType)

  _doc = $document[0]

  editor = {}

  $scope.quoteAndSend = () ->
    $scope.templateObj.quote()

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
    $scope.templateObj.save()

  $scope.data =
    htmlcontent: $scope.templateObj.mailCampaign.content

  $scope.applyTemplateClass = (qualifier = '') ->
    "#{$scope.$parent.templateType}#{qualifier}"

  $scope.doPreview = () ->
    $scope.templateObj.openPreview()
