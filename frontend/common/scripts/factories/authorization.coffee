# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
qs = require 'qs'
mod = require '../module.coffee'

mod.factory 'rmapsAuthorizationFactory', ($rootScope, $location, $log, rmapsPrincipalService, rmapsUrlHelpersService) ->
  $log = $log.spawn('frontend:map:rmapsAuthorizationFactory')
  routes = rmapsUrlHelpersService.getRoutes()

  doPermsCheck = (toState, desiredLocation, goToLocation) ->
    if not rmapsPrincipalService.isAuthenticated()
      # user is not authenticated, but needs to be.
      # set the route they wanted as a query parameter
      # then, send them to the signin route so they can log in
      $location.replace()
      $location.url routes.login + '?'+qs.stringify(next: desiredLocation)
      $log.debug 'redirected to login'
      return

    if not rmapsPrincipalService.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      $location.replace()
      $location.url routes.accessDenied
      $log.debug 'redirected to accessDenied'
      return

    if goToLocation
      # check if we're in authenticating state if authenticating path is substring in location-path
      # (switched to regex here so we don't need to worry about matching leading slash)
      if ///#{routes.authenticating}$///.test($location.path())
        $location.replace()
      $location.url desiredLocation


  return authorize: (toState, toParams, fromState, fromParams) ->
    if !toState?.permissionsRequired && !toState?.loginRequired
      # anyone can go to this state
      return

    desiredLocation = $location.path()+'?'+qs.stringify($location.search())

    # if we can, do check now (synchronously)
    if rmapsPrincipalService.isIdentityResolved()
      return doPermsCheck(toState, desiredLocation, false)
    # otherwise, go to temporary view and do check ASAP
    $location.replace()
    $location.url routes.authenticating
    rmapsPrincipalService.getIdentity().then () ->
      return doPermsCheck(toState, desiredLocation, true)


mod.run ($rootScope, rmapsAuthorizationFactory) ->
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    rmapsAuthorizationFactory.authorize(toState, toParams, fromState, fromParams)
    return
