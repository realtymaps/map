app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSelectTemplateCtrl', ($scope, rmapsMailTemplateTypeService, rmapsMailTemplate) ->

  $scope.displayCategory = 'all'

  $scope.categories = rmapsMailTemplateTypeService.getCategories()
  $scope.categoryLists = rmapsMailTemplateTypeService.getCategoryLists()

  $scope.campaign = rmapsMailTemplate.getCampaign()

  $scope.isEmptyCategory = () ->
    return $scope.displayCategory not of $scope.categoryLists or $scope.categoryLists[$scope.displayCategory].length == 0

  $scope.setCategory = (category) ->
    if !category?
      category = 'all'
    $scope.displayCategory = category

  $scope.selectTemplate = (idx) ->
    templateType = $scope.categoryLists[$scope.displayCategory][idx].type
    rmapsMailTemplate.setTemplateType(templateType)
    $scope.$parent.nextStep()
