app = require '../app.coffee'
_ = require 'lodash'

app.directive 'openAsModal', ($parse, $templateCache, $modal, $log, OpenAsModalWindowContext) ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    $log = $log.spawn 'frontend:map:openAsModal'
    $log.debug "openAsModal - attr based"

    openModal = () ->
      $log.debug "openModal() - #{scope.Toggles}"
      template = $templateCache.get(attrs.modalTemplate)

      windowClass = 'open-as-modal'
      windowClass += " #{attrs.windowClass}" if attrs.windowClass

      childScope = scope.$new false
      OpenAsModalWindowContext.modalTitle = attrs.modalTitle if attrs.modalTitle

      modal = $modal.open {
        animation: true
        scope: childScope
        controller: 'OpenAsModalWindowController'
        template: template
        windowClass: windowClass
        windowTemplateUrl: attrs.windowTemplateUrl
      }

      OpenAsModalWindowContext.modal = modal

    element.bind 'click', openModal
    scope.$on '$destroy', () ->
      element.unbind 'click', openModal

app.controller 'OpenAsModalWindowController', ($scope, OpenAsModalWindowContext) ->
  $scope.context = OpenAsModalWindowContext
  $scope.close = () ->
    OpenAsModalWindowContext.modal.close()

app.factory 'OpenAsModalWindowContext', () ->
  class OpenAsModalWindowContext
    modalTitle: null

  return new OpenAsModalWindowContext

