app = require '../../app.coffee'
_ = require 'lodash'

template = require './_propertyButtons.jade'

app.directive 'propertyButtons', ($rootScope, $state, rmapsResultsFormatterService, rmapsEventConstants, $log) ->
  $log.debug "Property Buttons directive: ", template
  return {
    restrict: 'EA'
    scope: {
      property: '='
    }
    template: template()
    controller: ($scope, $element, $attrs, $transclude) ->
      $log.debug "Property Buttons directive controller"

      $scope.zoomTo = ($event) ->
        $log.debug "ZOOM TO!!!!"
        $event.stopPropagation() if $event
        $rootScope.$emit rmapsEventConstants.map.zoomToProperty, $scope.property


      $scope.formatters = {
        results: new rmapsResultsFormatterService  scope: $scope
      }


  }
