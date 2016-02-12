app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSelectTemplateCtrl', ($rootScope, $scope, $log, rmapsMailTemplateTypeService, rmapsMailTemplateService) ->
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

  $rootScope.registerScopeData () ->
    $scope.$parent.initMailTemplate()
    .then () ->
      $scope.campaign = rmapsMailTemplateService.getCampaign()
