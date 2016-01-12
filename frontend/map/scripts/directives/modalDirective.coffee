app = require '../app.coffee'
_ = require 'lodash'

app.directive 'openAsModal', ($parse, $templateCache, $modal, $log) ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    $log = $log.spawn 'map:openAsModal'
    $log.debug "openAsModal - attr based"

    openModal = () ->
      $log.debug "openModal() - #{scope.Toggles}"
      template = $templateCache.get(attrs.modalTemplate)

      windowClass = 'open-as-modal'
      windowClass += " #{attrs.windowClass}" if attrs.windowClass

      modal = $modal.open {
        animation: true
        scope: scope
        controller: 'OpenAsModalWindowController'
        template: template
        windowClass: windowClass
        windowTemplateUrl: attrs.windowTemplateUrl
      }

      scope.$on 'rmapsOpenAsModal.close', () ->
        modal.close()

    element.bind 'click', openModal
    scope.$on '$destroy', () ->
      element.unbind 'click', openModal

app.controller 'OpenAsModalWindowController', ($scope) ->
  $scope.close = () ->
    $scope.$emit 'rmapsOpenAsModal.close'

