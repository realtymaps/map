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

  doPermsCheck = ({event, toState}) ->
    if not rmapsPrincipalService.isAuthenticated()
      # user is not authenticated, but needs to be.
      # $log.debug 'redirected to login'
      redirect routes.login, event
      return

    if not rmapsPrincipalService.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      # $log.debug 'redirected to accessDenied'
      redirect routes.accessDenied, event
      return

    if toState?.profileRequired and !rmapsPrincipalService.isCurrentProfileResolved()
      # $log.debug 'redirected to profiles'
      redirect routes.profiles, event
      return

  return authorize: ({event, toState}) ->
    if !toState?.permissionsRequired && !toState?.loginRequired
      # anyone can go to this state
      return

    # if we can, do check now (synchronously)
    if rmapsPrincipalService.isIdentityResolved()
      return doPermsCheck({event, toState})

    # otherwise, go to temporary view and do check ASAP
    redirect routes.authenticating, event

    rmapsPrincipalService.getIdentity().then () ->
      return doPermsCheck({event, toState})


mod.run ($rootScope, rmapsAuthorizationFactory, rmapsEventConstants, $state) ->
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    rmapsAuthorizationFactory.authorize({event, toState, toParams, fromState, fromParams})
    return

  $rootScope.$on rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    rmapsAuthorizationFactory.authorize {event, toState: $state.current}
