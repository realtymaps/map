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
app.directive 'mobileModalHeader', (rmapsPageService) ->
  rmapsPageService.mobile.modal = true

app.directive 'mobileCustomHeader', (rmapsPageService) ->
  rmapsPageService.mobile.custom = true

app.directive 'mobileHeaderButtons', ($parse, $templateCache, $uibModal, $log, rmapsMobileHeaderContextFactory) ->
  $log = $log.spawn "mobileHeader"
  return {
    restrict: 'E'
    transclude: true
    scope:
      headerId: '@'
      buttonType: '@'
    controller: ($scope, $element, $attrs, $transclude) ->
      $log.debug "MOBILE-HEADER-BUTTONS Link page view directive:", $scope.headerId, $scope.buttonType
      headerId = $scope.headerId || 'mobile-header'
      buttonType = $scope.buttonType || 'right'
      rmapsMobileHeaderContextFactory.setButtons headerId, buttonType, $transclude
  }
