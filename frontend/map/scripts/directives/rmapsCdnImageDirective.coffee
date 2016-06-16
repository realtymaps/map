app = require '../app.coffee'

#
# This directive applied to an img tag will attempt to load via CDN and fallback to the local URL
#
# Example: <img rmaps-cdn-image src="/assets/some_image.png" />
#
app.directive 'rmapsCdnImage', ($rootScope, $log, $compile) ->
  $log = $log.spawn 'rmapsCdnImage'

  restrict: 'A'
  terminal: true
  priority: 1000

  link: (scope, element, attrs) ->
    if element[0].tagName != 'IMG'
      $log.warn 'rmaps-cdn-image was used on a non-image tag!'
      return

    if element.attr('src')
      originalSrc = attrs.src

      element.bind 'error', ->
        element.unbind 'error'
        element.attr('src', originalSrc)

      if originalSrc.indexOf('http') != 0
        element.attr('src', 'http://prodpull1.realtymapsterllc.netdna-cdn.com' + originalSrc)

    element.removeAttr('rmaps-cdn-image')
    $compile(element)(scope)
