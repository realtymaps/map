###globals google###
app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'

# fix google map views after changing back to map state
app.run ($rootScope, $timeout, rmapsCurrentMapService) ->
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    map = rmapsCurrentMapService.get()
    # if we're not entering the map state, or if we're already on the map state, don't do anything
    if toState.url != frontendRoutes.map || fromState.url == frontendRoutes.map
      return

    return unless map?.scope?.controls?.streetView?
    $timeout () ->
      # main map
      map?.scope.control.refresh?()
      # street view map -- TODO: this doesn't work for street view, not sure why
      gStrMap = map?.scope.controls.streetView.getGObject?()
      if gStrMap?
        google.maps.event.trigger(gStrMap, 'resize')
    , 500
