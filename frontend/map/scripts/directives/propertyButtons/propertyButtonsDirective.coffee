app = require '../../app.coffee'
_ = require 'lodash'

template = require './_propertyButtons.jade'
#
# USAGE:
#
#   The property and project should be passed in using directive attributes:
#
#      <property-buttons project="projectScopeVar" property="propertyScopeVar" ... ></property-buttons>
#
#   Or the JADE equivalent:
#
#      property-buttons(project="projectScopeVar" property="propertyScopeVar")
#
#   If a project is not defined, the currently selected project will be used
#
app.directive 'propertyButtons', (
  $log
  $rootScope,
  $state,
  rmapsEventConstants,
  rmapsProfilesService,
  rmapsPropertiesService,
  rmapsPropertyFormatterService,
  rmapsResultsFormatterService,
) ->
#  $log.debug "Property Buttons directive: ", template
  return {
    restrict: 'EA'
    scope:
      propertyFn: '&property'
      projectFn: '&?project'
      zoomClick: '&?'
      pinClick: '&?'
      favoriteClick: '&?'
    template: template()
    controller: ($scope, $element, $attrs, $transclude) ->
#      $log.debug "PROPERTY BUTTONS with property", $scope.property, "and project", $scope.project
      $scope.formatters = {
        results: new rmapsResultsFormatterService  scope: $scope
        property: new rmapsPropertyFormatterService()
      }

      $scope.property = $scope.propertyFn()

      if !$scope.projectFn
        $scope.project = rmapsProfilesService.currentProfile
      else
        $scope.project = $scope.projectFn()

      $scope.zoomTo = ($event) ->
        $event.stopPropagation() if $event

        proceed = true
        if $scope.zoomClick
          proceed = $scope.zoomClick { property: $scope.property }

        if proceed
          $rootScope.$emit rmapsEventConstants.map.zoomToProperty, $scope.property

      $scope.pin = ($event) ->
        $event.stopPropagation() if $event

        proceed = true
        if $scope.pinClick
          proceed = $scope.pinClick { property: $scope.property }

        if proceed
          rmapsPropertiesService.pinUnpinProperty($scope.property)

      $scope.favorite = ($event) ->
        $event.stopPropagation() if $event

        proceed = true
        if $scope.favoriteClick
          proceed = $scope.favoriteClick { property: $scope.property }

        if proceed
          rmapsPropertiesService.favoriteProperty($scope.property)

  }
