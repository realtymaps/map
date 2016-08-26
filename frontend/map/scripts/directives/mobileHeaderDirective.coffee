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
app.factory 'rmapsMobileHeaderContextFactory', ($log) ->
  $log = $log.spawn "mobileHeader"

  class MobileHeaderContextManager
    _headers: {}
    _deferredButtonsByHeader: {}

    # Register a header controller that will use buttons
    registerHeader: (headerId, header) ->
      $log.debug "Mobile Header Context - Register Header", headerId
      @_headers[headerId] = header

      if @_deferredButtonsByHeader[headerId]
        angular.forEach @_deferredButtonsByHeader[headerId], (transclude, type) ->
          header.setButtons type, transclude

        delete @_deferredButtonsByHeader[headerId]

    # Register a button for a location in a header.  Locations are 'left' 'center' 'right'
    setButtons: (headerId, type, transclude) ->
      $log.debug "Mobile Header Context - Set buttons for header", headerId, "- type", type
      header = @_headers[headerId]

      if header
        header.setButtons type, transclude
      else
        buttonsByType = @_deferredButtonsByHeader[headerId]
        if !buttonsByType
          buttonsByType = @_deferredButtonsByHeader[headerId] = {}

        buttonsByType[type] = transclude

    removeHeader: (headerId) ->
      $log.debug "Mobile Header Context - Removing header reference for id", headerId
      delete @_headers[headerId]

  return new MobileHeaderContextManager

#
# Controller used by the header directive
#
headerCtrlId = 1
app.controller 'rmapsMobileHeaderCtrl', ($scope, $element, $attrs, $compile, $log, rmapsMobileHeaderContextFactory) ->
  $log = $log.spawn "mobileHeader"

  class MobileHeaderController
    _targets: {}
    _deferredButtons: {}
    _headerId: null

    constructor: () ->
      $log.debug "CONSTRUCT header ctrl #{headerCtrlId}"
      headerCtrlId++

      $scope.$on "$destroy", () =>
        $log.debug "DESTROY scope for mobile header:", @_headerId
        rmapsMobileHeaderContextFactory.removeHeader @_headerId if @_headerId

    # Initialize the header controller with the header id that is specified for this header
    init: (headerId) ->
      $log.debug "INIT header ctrl for header id", headerId
      @_headerId = headerId
      rmapsMobileHeaderContextFactory.registerHeader headerId, @

    # If the header has a defined sub-directive allowing a location to be targeted, execute the
    # transclusion function for the buttons for that location
    # If buttons are being set but the target location is not yet registered... save the button transclude function
    setButtons : (type, transclude) ->
      $log.debug "SET BUTTONS for header", @_headerId, "- type", type
      if @_targets[type]
        @_transcludeButtons type, transclude
      else
        @_deferredButtons[type] = transclude

    # Register a target element that can hold buttons in the header
    # If buttons had been previously registered, transclude them now and delete the saved transclude function
    registerTargetElement: (type, targetElement) ->
      $log.debug "REGISTER TARGET for header", @_headerId, "- type", type
      @_targets[type] = targetElement

      if @_deferredButtons[type]
        $log.debug "Found deferred buttons for header", @_headerId, "- type", type
        @_transcludeButtons type, @_deferredButtons[type]
        delete @_deferredButtons[type]

    # Private function to execute the button transclude function on the correct target location
    _transcludeButtons: (type, transclude) ->
      $log.debug "TRANSCLUDE buttons to target for header", @_headerId, "- type", type
      transclude (buttonClone, buttonScope) =>
        @_targets[type].append buttonClone

  return new MobileHeaderController

#
# Mobile header directive
#
app.directive 'mobileHeader', ($parse, $templateCache, $uibModal, $log) ->
  $log = $log.spawn "mobileHeader"

  return {
    restrict: 'E'
    controller: 'rmapsMobileHeaderCtrl'
    priority: 1000
    scope:
      headerId: '@'
    compile: (tElement, tAttrs) ->
      pre: ($scope, $element, $attrs, controller) ->
        $log.debug "mobile-header directive link function"
        headerId = $scope.headerId || 'mobile-header'
        controller.init headerId
  }

#
# Constructs instances of button target directives for each location
#
createMobileHeaderTargetDirective = ($log, type) ->
  $log = $log.spawn "mobileHeader"

  return {
    restrict: 'EAC'
    require: '^mobileHeader',
    priority: 999
    link: ($scope, $element, $attrs, rmapsMobileHeaderCtrl) ->
      $log.debug "MOBILE-HEADER-TARGET directive link function"
      rmapsMobileHeaderCtrl.registerTargetElement(type, $element)
  }

app.directive 'mobileHeaderTargetRight', ($log) ->
  createMobileHeaderTargetDirective($log, 'right')

app.directive 'mobileHeaderTargetLeft', ($log) ->
  createMobileHeaderTargetDirective($log, 'left')

app.directive 'mobileHeaderTargetCenter', ($log) ->
  createMobileHeaderTargetDirective($log, 'center')

