app = require '../app.coffee'
_ = require 'lodash'

app.directive 'mobileHeaderButtons', ($parse, $templateCache, $modal, $log, mobileHeaderContext) ->
  restrict: 'E'
  link: ($scope, $element, $attrs, controller) ->
#    $log.debug "!!! Mobile Header Buttons Directive Link - class: '#{$element[0].className}'"

    html = $element.html()
    mobileHeaderContext.setButtons "global", "right", html

    $element.empty()
