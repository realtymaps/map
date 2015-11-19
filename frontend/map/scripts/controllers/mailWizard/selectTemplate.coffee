app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSelectTemplateCtrl', ($rootScope, $scope, $state, $log, rmapsprincipal, rmapsMailTemplate, rmapsMailTemplateTypeService) ->
  $log.debug "#### rmapsSelectTemplateCtrl"

  $log.debug "#### rmapsMailTemplate:"
  $log.debug rmapsMailTemplate

  $log.debug "#### rmapsTemplateTypeService:"
  $log.debug rmapsTemplateTypeService


  $scope.templatesArray = [
    name: "basicLetter"
    thumb: "path/to/basicLetter"
  ,
    name: "formalLetter"
    thumb: "path/to/formalLetter"
  ]

  $scope.$parent.templateType = {}


  $scope.selectTemplate = (idx) ->
    $scope.$parent.templateType = $scope.templatesArray[idx].name

  $scope.filterByType = (type) ->
    if !type?
      return 
    $log.debug "#### filtering by type #{type}..."
