app = require '../../app.coffee'
_ = require 'lodash'

template = require './_propertyButtons.jade'

app.directive 'propertyButtons', ($rootScope, $state, rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsPropertiesService, rmapsEventConstants, $log) ->
  $log.debug "Property Buttons directive: ", template
  return {
    restrict: 'EA'
    scope:
      property: '='
      project: '=?'
      zoomClick: '&?'
      pinClick: '&?'
      favoriteClick: '&?'
    template: template()
    controller: ($scope, $element, $attrs, $transclude) ->
      $log.debug "PROPERTY BUTTONS with property", $scope.property, "and project", $scope.project
      $scope.formatters = {
        results: new rmapsResultsFormatterService  scope: $scope
        property: new rmapsPropertyFormatterService()
      }

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
