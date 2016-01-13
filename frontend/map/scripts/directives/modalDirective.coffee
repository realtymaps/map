app = require '../app.coffee'
_ = require 'lodash'

createModalDirective = ($parse, $templateCache, $modal, $log, OpenAsModalWindowContext, options) ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    $log = $log.spawn 'map:openAsModal'

    # Open a modal window when the element is clicked
    openModal = () ->
      $log.debug "openModal() - #{scope.Toggles}"

      childScope = scope.$new false

      # Determine the window template url, if provided
      templateExpr = attrs.modalTemplate || options.modalTemplate
      templateName = scope.$eval templateExpr

      template = $templateCache.get templateName

      # Determine the window class
      windowClass = 'open-as-modal'
      windowClass += " #{options.windowClass}" if options.windowClass
      windowClass += " #{attrs.windowClass}" if attrs.windowClass

      # Evaluate the title as an expression if provided
      title = options.modalTitle || ''
      if attrs.modalTitle
        title = scope.$eval attrs.modalTitle

      OpenAsModalWindowContext.modalTitle = title

      # Open the modal
      modal = $modal.open {
        animation: true
        scope: childScope
        controller: 'OpenAsModalWindowController'
        template: template
        windowClass: windowClass
        windowTemplateUrl: attrs.windowTemplateUrl || options.windowTemplateUrl
      }

      # Set the modal on the context to pass title and handle close event
      OpenAsModalWindowContext.modal = modal

    # Bind the click event on the modal element to launch the modal window and
    # remove the click handler when the scope is destroyed
    element.bind 'click', openModal
    scope.$on '$destroy', () ->
      element.unbind 'click', openModal

app.directive 'openAsModal', ($parse, $templateCache, $modal, $log, OpenAsModalWindowContext) ->
  createModalDirective $parse, $templateCache, $modal, $log, OpenAsModalWindowContext

app.directive 'mobileModal', ($parse, $templateCache, $modal, $log, OpenAsModalWindowContext) ->
  options =
    windowTemplateUrl: "./includes/_mobile_modal_window.jade"
    windowClass: "mobile-view mobile-modal-window"

  createModalDirective $parse, $templateCache, $modal, $log, OpenAsModalWindowContext, options

app.controller 'OpenAsModalWindowController', ($scope, OpenAsModalWindowContext) ->
  $scope.context = OpenAsModalWindowContext
  $scope.close = () ->
    OpenAsModalWindowContext.modal.close()

app.factory 'OpenAsModalWindowContext', () ->
  class OpenAsModalWindowContext
    modalTitle: null

  return new OpenAsModalWindowContext

