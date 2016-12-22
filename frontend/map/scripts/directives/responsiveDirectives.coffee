app = require '../app.coffee'


#
# This is based on the ngIf directive implementation, but is applied to CSS class selectors
#
generateViewDirective = ($animate, $window, showView) ->
  {
    multiElement: true
    transclude: 'element'
    priority: 600
    terminal: true
    restrict: 'EAC'
    $$tlb: true
    link: ($scope, $element, $attr, ctrl, $transclude) ->
      block = undefined
      childScope = undefined
      previousElements = undefined

      if showView
        if !childScope
          $transclude (clone, newScope) ->
            childScope = newScope
            clone[clone.length++] = document.createComment(' end desktopOnly ')
            # Note: We only need the first/last node of the cloned nodes.
            # However, we need to keep the reference to the jqlite wrapper as it might be changed later
            # by a directive with templateUrl when its template arrives.
            block = clone: clone
            $animate.enter clone, $element.parent(), $element
            return
      else
        if previousElements
          previousElements.remove()
          previousElements = null
        if childScope
          childScope.$destroy()
          childScope = null
        if block
          previousElements = angular.getBlockNodes(block.clone)
          $animate.leave(previousElements).then ->
            previousElements = null
            return
          block = null
      return
  }

#
# Directive targeting .desktop-only CSS selector
#
app.directive 'desktopOnly', ($animate, $window, rmapsResponsiveViewService) ->
  return generateViewDirective($animate, $window, rmapsResponsiveViewService.isDesktopView())

#
# Directive targeting .mobile-only CSS selector
#
app.directive 'mobileOnly', ($animate, $window, rmapsResponsiveViewService) ->
  return generateViewDirective($animate, $window, rmapsResponsiveViewService.isMobileView())
