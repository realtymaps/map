app = require '../app.coffee'
_ = require 'lodash'

#
# Directive allowing a view or modal to specify buttons to be added to a header in a different
# location in the DOM.  This directive uses transclusion so that any click events or other $scope
# usage will be in the context of the view/modal scope and *not* the header
#
# Usage:
#
#  mobile-header-buttons   <-- buttons directive
#    a(ng-click="doSomething()") View-Specific Button   <-- This will execute in the $scope of the view/modal
#
app.directive 'mobileHeaderButtons', ($parse, $templateCache, $modal, $log, mobileHeaderContext) ->
  restrict: 'E'
  transclude: true
  scope:
    buttonType: '@'
  controller: ($scope, $element, $attrs, $transclude) ->
    mobileHeaderContext.setButtons $scope.headerId || 'mobile-header', $scope.buttonType || 'right', $transclude
