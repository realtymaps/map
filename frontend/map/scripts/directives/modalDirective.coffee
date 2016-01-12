app = require '../app.coffee'
_ = require 'lodash'

app.directive 'openAsModal', ($parse, $templateCache, $modal, $log) ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    $log = $log.spawn 'map:openAsModal'
    $log.debug "openAsModal - attr based"

    openModal = () ->
      template = $templateCache.get(attrs.modalTemplate)
      $log.debug "openAsModal template - #{template}"

      windowClass = 'open-as-modal'
      windowClass += " #{attrs.windowClass}" if attrs.windowClass

      childScope = scope.$new false

      modal = $modal.open {
        animation: true
        scope: childScope
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
  $scope.fireCloseEvent = () ->
    $scope.$emit 'rmapsOpenAsModal.close'

