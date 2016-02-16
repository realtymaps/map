app = require '../../app.coffee'
_ = require 'lodash'
modalTemplate = require('../../../html/views/templates/modal-mailPreview.tpl.jade')()

module.exports = app

app.controller 'rmapsSelectTemplateCtrl', ($rootScope, $scope, $log, $modal, rmapsMailTemplateTypeService, rmapsMailTemplateService) ->
  $log = $log.spawn 'mail:rmapsSelectTemplateCtrl'
  $log.debug 'rmapsSelectTemplateCtrl'

  $scope.displayCategory = 'all'

  $scope.categories = rmapsMailTemplateTypeService.getCategories()
  $scope.categoryLists = rmapsMailTemplateTypeService.getCategoryLists()

  $scope.campaign = rmapsMailTemplateService.getCampaign()

  $scope.isEmptyCategory = () ->
    return $scope.displayCategory not of $scope.categoryLists or $scope.categoryLists[$scope.displayCategory].length == 0

  $scope.setCategory = (category) ->
    if !category?
      category = 'all'
    $scope.displayCategory = category

  $scope.selectTemplate = (idx) ->
    templateType = $scope.categoryLists[$scope.displayCategory][idx].type
    $log.debug "templateType chosen: #{templateType}"
    rmapsMailTemplateService.setTemplateType(templateType)
    $scope.campaign = rmapsMailTemplateService.getCampaign()

  $scope.previewTemplate = (template) ->
    modalInstance = $modal.open
      template: modalTemplate
      controller: 'rmapsMailTemplatePreviewCtrl'
      openedClass: 'preview-mail-opened'
      windowClass: 'preview-mail-window'
      windowTopClass: 'preview-mail-windowTop'
      resolve:
        template: () ->
          content: rmapsMailTemplateTypeService.getHtml(template.type)
          category: template.category
          title: template.name

  $rootScope.registerScopeData () ->
    $scope.$parent.initMailTemplate()
    .then () ->
      $scope.campaign = rmapsMailTemplateService.getCampaign()
