app = require '../app.coffee'

app.service 'rmapsResponsiveViewService', ($window) ->
  xs        = 768
  mobile = "(max-width: #{xs - 1}px)"
  mobileMQL = $window.matchMedia mobile

  isMobileView: () ->
    return mobileMQL.matches

  isDesktopView: () ->
    return !mobileMQL.matches
