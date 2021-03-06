app = require '../../app.coffee'

app.directive 'propertyAttributes',
  (
    $rootScope
    $state
    rmapsResultsFormatterService
    rmapsPropertyFormatterService
  ) ->
    return {
      restrict: 'EA'
      scope:
        property: '='
      templateUrl: './includes/directives/property/_propertyAttributesDirective.jade'
      controller: ($scope, $element, $attrs, $transclude) ->
        $scope.formatters = {
          property: rmapsPropertyFormatterService
        }
    }
