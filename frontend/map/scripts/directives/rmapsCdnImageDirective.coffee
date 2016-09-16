app = require '../app.coffee'

#
# This directive applied to an img tag will attempt to load via CDN and fallback to the local URL
#
# Example: <img rmaps-cdn-image src="/assets/some_image.png" />
#      or  <img rmaps-cdn-image ng-src="/assets/{{some_image}}.png" />
#
app.directive 'rmapsCdnImage', ($rootScope, $log, $compile, $interpolate) ->
  $log = $log.spawn 'rmapsCdnImage'

  restrict: 'A'
  priority: 1000
  terminal: true

  link: (scope, element, attrs) ->
    if element[0].tagName != 'IMG'
      $log.warn 'rmaps-cdn-image was used on a non-image tag!'
      return

    remap = (srcAttr, originalSrc = element.attr(srcAttr)) ->
      $log.debug "original #{srcAttr}:", originalSrc

      if originalSrc?.indexOf('http') != 0
        shard = (originalSrc.match(/.*\/(\w+)\.\w+/)?[1]?.charCodeAt(0) || 0) % 2
        element.attr(srcAttr, "//prodpull#{shard+1}.realtymapsterllc.netdna-cdn.com#{originalSrc}")
        $log.debug "new #{srcAttr}", element.attr(srcAttr)

        element.bind 'error', ->
          originalSrc = $interpolate(originalSrc)(scope)
          $log.debug "falling back to #{originalSrc}"
          element.unbind 'error'
          element.attr('src', originalSrc)

    if 'src' of attrs
      remap 'src'
    else if 'ngSrc' of attrs
      $log.debug "ngSrc: #{attrs.ngSrc}"
      remap 'ng-src', attrs.ngSrc
    else
      return

    element.removeAttr('rmaps-cdn-image')
    $compile(element)(scope)
