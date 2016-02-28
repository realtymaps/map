app = require '../../app.coffee'
_ = require 'lodash'

template = require './_propertyButtons.jade'

app.directive 'propertyButtons', ($rootScope, $state, rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsPropertiesService, rmapsEventConstants, $log) ->
  $log.debug "Property Buttons directive: ", template
  return {
    restrict: 'EA'
    scope:
      property: '='
      zoomClick: '&?'
    template: template()
    controller: ($scope, $element, $attrs, $transclude) ->
      $log.debug "PROPERTY BUTTONS with property", $scope.property
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

        rmapsPropertiesService.save

      $scope.favorite = ($event) ->
        $event.stopPropagation() if $event


  }
