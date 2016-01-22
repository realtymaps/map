app = require '../app.coffee'
_ = require 'lodash'

app.factory 'mobileHeaderContext', ($log) ->
  class MobileHeaderContextManager
    _headers: {}

    registerHeader: (headerId, controller) ->
      @_headers[headerId] = controller

    setButtons: (headerId, type, transclude) ->
      header = @_headers[headerId]

      if !header
        $log.error "No Mobile Header controller available for id #{headerId}"
        return

      header.setButtons type, transclude

  return new MobileHeaderContextManager

app.controller 'mobileHeaderController', ($scope, $element, $attrs, $compile, $log, mobileHeaderContext) ->
  $log.debug "!!! Mobile Header Controller - class: '#{$element[0].className}'"
  class MobileHeaderController
    _targets: {}

    constructor: () ->
      $log.debug ">>> constructor - class: '#{$element[0].className}'"
      mobileHeaderContext.registerHeader "global", @

      $scope.buttons = { }

    setButtons : (type, transclude) ->
      $log.debug "!!! Set buttons of type '#{type}'"
#      $scope.buttons[type] = transclude

      if @_targets[type]
        transclude (buttonClone, buttonScope) =>
          @_targets[type].append buttonClone

    registerTargetElement: (type, targetElement) ->
      @_targets[type] = targetElement;

  return new MobileHeaderController


app.directive 'mobileHeader', ($parse, $templateCache, $modal, $log) ->
  restrict: 'E'
  controller: 'mobileHeaderController'
  priority: 1000

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

