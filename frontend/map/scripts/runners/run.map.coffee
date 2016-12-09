###globals google###
app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
{defer} = require '../../../../common/utils/util.promise.coffee'


rootScopeDefer = defer()


# fix google map views after changing back to map state
app.run (
$http
$q
$log
$rootScope
$timeout
rmapsCurrentMapService
rmapsMainOptions
rmapsMapTogglesFactory
rmapsUsStates) ->

  $log = $log.spawn('map:runner:run.map')

  $rootScope.us_states = rmapsUsStates.all

  $rootScope.updateToggles = (map_toggles = {}) ->
    $log.debug 'updateToggles', map_toggles
    $rootScope.Toggles = rmapsMainOptions.map.toggles = new rmapsMapTogglesFactory(map_toggles)

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

  $rootScope.safeConfigPromise = $http.getData(backendRoutes.config.safeConfig)

  $rootScope.safeConfigPromise.then (data) ->
    $rootScope.safeConfig = data

  $rootScope.stripePromise = $rootScope.safeConfigPromise
  .then (data) ->
    if !data?.stripe?
      msg = "stripe setting undefined"
      $log.error msg
      return $q.reject(new Error(msg))

    data.stripe

  rootScopeDefer.resolve($rootScope)


module.exports = {
  rootScopePromise: rootScopeDefer.promise
}
