app = require '../app.coffee'

createModalDirective = ($parse, $uibModal, $log, rmapsOpenAsModalWindowContextFactory, options) ->
  restrict: 'A'
  link: (scope, element, attrs) ->
#    $log = $log.spawn 'map:openAsModal'

    # Open a modal window when the element is clicked
    openModal = () ->
      $log.debug "openModal() - #{scope.Toggles}"

      childScope = scope.$new false

      # Determine the window template url, if provided
      templateExpr = attrs.modalTemplate || options.modalTemplate
      templateName = scope.$eval templateExpr

      # Determine the window class
      windowClass = 'open-as-modal'
      windowClass += " #{options.windowClass}" if options.windowClass
      windowClass += " #{attrs.windowClass}" if attrs.windowClass

      # Evaluate the title as an expression if provided
      title = options.modalTitle || ''
      if attrs.modalTitle
        title = scope.$eval attrs.modalTitle

      rmapsOpenAsModalWindowContextFactory.modalTitle = title

      # Open the modal
      modal = $uibModal.open {
        animation: true
        scope: childScope
        controller: 'OpenAsModalWindowCtrl'
        templateUrl: templateName
        windowClass: windowClass
        windowTemplateUrl: attrs.windowTemplateUrl || options.windowTemplateUrl
      }

      # Set the modal on the context to pass title and handle close event
      rmapsOpenAsModalWindowContextFactory.modal = modal

    # Bind the click event on the modal element to launch the modal window and
    # remove the click handler when the scope is destroyed
    element.bind 'click', openModal
    scope.$on '$destroy', () ->
      element.unbind 'click', openModal

app.directive 'openAsModal', ($parse, $uibModal, $log, rmapsOpenAsModalWindowContextFactory) ->
  createModalDirective $parse, $uibModal, $log, rmapsOpenAsModalWindowContextFactory

app.directive 'mobileModal', ($parse, $uibModal, $log, rmapsOpenAsModalWindowContextFactory) ->
  options =
    windowTemplateUrl: "./includes/_mobile_modal_window.jade"
    windowClass: "mobile-view mobile-modal-window"

  createModalDirective $parse, $uibModal, $log, rmapsOpenAsModalWindowContextFactory, options

app.controller 'OpenAsModalWindowCtrl', ($scope, rmapsOpenAsModalWindowContextFactory) ->
  $scope.context = rmapsOpenAsModalWindowContextFactory
  $scope.close = () ->
    rmapsOpenAsModalWindowContextFactory.modal.close()

app.factory 'rmapsOpenAsModalWindowContextFactory', () ->
  class OpenAsModalWindowContextFactory
    modalTitle: null

  return new OpenAsModalWindowContextFactory
