# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
mod = require '../module.coffee'

mod.factory 'rmapsAuthorizationFactory', ($rootScope, $timeout, $location, $log, $state, rmapsPrincipalService, rmapsUrlHelpersService) ->
  $log = $log.spawn('map:rmapsAuthorizationFactory')
  routes = rmapsUrlHelpersService.getRoutes()

  redirect = (stateName, event) ->
    #as stated in stackoverflow this avoids race hell in ui-router
    event?.preventDefault()
    $timeout ->
      $state.go stateName

  doPermsCheck = (toState) ->
    if not rmapsPrincipalService.isAuthenticated()
      # user is not authenticated, but needs to be.
      # $log.debug 'redirected to login'
      return routes.login

    if not rmapsPrincipalService.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      # $log.debug 'redirected to accessDenied'
      return routes.accessDenied

    if toState?.profileRequired and !rmapsPrincipalService.isCurrentProfileResolved()
      # $log.debug 'redirected to profiles'
      return routes.profiles

  return authorize: ({event, toState}) ->
    if !toState?.permissionsRequired && !toState?.loginRequired
      # anyone can go to this state
      return

    # if we can, do check now (synchronously)
    if rmapsPrincipalService.isIdentityResolved()
      stateName = doPermsCheck(toState)
      if stateName
        redirect stateName, event

    # otherwise, go to temporary view and do check ASAP
    else
      redirect routes.authenticating, event

      rmapsPrincipalService.getIdentity().then () ->
        stateName = doPermsCheck(toState) || toState.name
        redirect stateName

mod.run ($rootScope, rmapsAuthorizationFactory, rmapsEventConstants, $state) ->
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    rmapsAuthorizationFactory.authorize({event, toState, toParams, fromState, fromParams})
    return

  $rootScope.$on rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    rmapsAuthorizationFactory.authorize {event, toState: $state.current}
