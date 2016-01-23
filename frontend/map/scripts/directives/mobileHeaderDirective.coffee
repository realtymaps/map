app = require '../app.coffee'
_ = require 'lodash'

#
# Set of Directives to define a common header that will allow buttons to be placed by a view or modal located
# in a disjoint location in the DOM
#
# Usage:
#
# mobile-header    <-- header directive
#   .mobile-header-left    <-- css style for button(s) on the left (e.g. - back button)
#      mobile-header-button-left    <-- directive acting as target for view buttons on the left
#   .mobile-header-center    <-- css style for central area of header (e.g. - title)
#      mobile-header-button-center    <-- directive acting as target for view buttons for the center
#   .mobile-header-right   <-- css style for button(s) on the right (e.g. - close button)
#      mobile-header-button-right   <-- directive acting as target for view buttons on the right
#

#
# Service that is shared by the header directive and the buttons directives to pass transclusion functions
#
app.factory 'mobileHeaderContext', ($log) ->
  class MobileHeaderContextManager
    _headers: {}

    # Register a header controller that will use buttons
    registerHeader: (headerId, controller) ->
      @_headers[headerId] = controller

    # Register a button for a location in a header.  Locations are 'left' 'center' 'right'
    setButtons: (headerId, type, transclude) ->
      header = @_headers[headerId]

      if !header
        $log.error "No Mobile Header controller available for id #{headerId}"
        return

      header.setButtons type, transclude

  return new MobileHeaderContextManager

#
# Controller used by the header directive
#
app.controller 'mobileHeaderController', ($scope, $element, $attrs, $compile, $log, mobileHeaderContext) ->
  class MobileHeaderController
    _targets: {}

    constructor: () ->
      $scope.buttons = { }

    # Initialize the header controller with the header id that is specified for this header
    init: (headerId) ->
      mobileHeaderContext.registerHeader headerId, @

    # If the header has a defined sub-directive allowing a location to be targeted, execute the
    # transclusion function for the buttons for that location
    setButtons : (type, transclude) ->
      if @_targets[type]
        transclude (buttonClone, buttonScope) =>
          @_targets[type].append buttonClone

    # Register a target element that can hold buttons in the header
    registerTargetElement: (type, targetElement) ->
      @_targets[type] = targetElement;

  return new MobileHeaderController

#
# Mobile header directive
#
app.directive 'mobileHeader', ($parse, $templateCache, $modal, $log) ->
  restrict: 'E'
  controller: 'mobileHeaderController'
  priority: 1000
  scope:
    headerId: '@'
  link: ($scope, $element, $attrs, controller) ->
    controller.init($scope.headerId || 'mobile-header')

#
# Constructs instances of button target directives for each location
#
createMobileHeaderButtonDirective = (type) ->
  return {
    restrict: 'EAC'
    require: '^mobileHeader',
    priority: 999
    link: ($scope, $element, $attrs, mobileHeaderController) ->
      mobileHeaderController.registerTargetElement(type, $element)
  }

app.directive 'mobileHeaderButtonRight', () ->
  createMobileHeaderButtonDirective('right')

app.directive 'mobileHeaderButtonLeft', () ->
  createMobileHeaderButtonDirective('left')

app.directive 'mobileHeaderButtonCenter', () ->
  createMobileHeaderButtonDirective('center')

