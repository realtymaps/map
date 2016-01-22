app = require '../app.coffee'
_ = require 'lodash'

app.directive 'mobileHeaderButtons', ($parse, $templateCache, $modal, $log, mobileHeaderContext) ->
  restrict: 'E'
  transclude: true
  controller: ($scope, $element, $attrs, $transclude) ->
    $log.debug "!!! Mobile Header Buttons Controller - class: '#{$element[0].className}'"
    mobileHeaderContext.setButtons "global", "right", $transclude
