app = require '../app.coffee'
_ = require 'lodash'

app.directive 'mobileHeaderButtons', ($parse, $templateCache, $modal, $log, mobileHeaderContext) ->
  restrict: 'E'
  transclude: true
  scope:
    buttonType: '@'
  controller: ($scope, $element, $attrs, $transclude) ->
    mobileHeaderContext.setButtons $scope.headerId || 'mobile-header', $scope.buttonType || 'right', $transclude
