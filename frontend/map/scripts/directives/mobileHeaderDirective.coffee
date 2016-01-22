app = require '../app.coffee'
_ = require 'lodash'

app.factory 'mobileHeaderContext', ($log) ->
  class MobileHeaderContextManager
    _headers: {}

    registerHeader: (headerId, controller) ->
      @_headers[headerId] = controller

    setButtons: (headerId, type, html) ->
      header = @_headers[headerId]

      if !header
        $log.error "No Mobile Header controller available for id #{headerId}"
        return

      header.setButtons type, html

  return new MobileHeaderContextManager

app.controller 'mobileHeaderController', ($scope, $element, $attrs, $compile, $log, mobileHeaderContext) ->
  $log.debug "!!! Mobile Header Controller - class: '#{$element[0].className}'"
  class MobileHeaderController

    constructor: () ->
      $log.debug ">>> constructor - class: '#{$element[0].className}'"
      mobileHeaderContext.registerHeader "global", @

      $scope.buttons = { }

    setButtons : (type, html) ->
      $log.debug "!!! Set buttons of type '#{type}'"
      $scope.buttons[type] = html

  return new MobileHeaderController


app.directive 'mobileHeader', ($parse, $templateCache, $modal, $log) ->
  restrict: 'E'
  controller: 'mobileHeaderController'
  priority: 1000

