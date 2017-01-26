# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
app = require '../app.coffee'

app.factory 'rmapsMapAuthorizationFactory', (
  $location,
  $log,
  $rootScope,
  $state,
  $stateParams,
  rmapsPrincipalService,
  rmapsPriorStateService,
  rmapsUrlHelpersService,
  rmapsProfilesService
) ->

  $log = $log.spawn('map:rmapsMapAuthorizationFactory')

  #
  # Private
  #

  routes = rmapsUrlHelpersService.getRoutes()

  redirect = ({state, params, event, options}) ->
    #as stated in stackoverflow this avoids race hell in ui-router
    event?.preventDefault()

    $log.debug "Redirect to #{state.name || state}"
    return $state.go state, params, options

  doPermsCheck = (toState, toParams) ->
    if not rmapsPrincipalService.isAuthenticated()
      # user is not authenticated, but needs to be.
      $log.debug 'redirected to login'
      rmapsPriorStateService.setPrior toState, toParams
      return routes.login

    if not rmapsPrincipalService.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      $log.debug 'redirected to accessDenied'
      return routes.accessDenied

  #
  # Service Definition
  #

  service =
    # Force the app to navigate to the login screen but retain the current state and params for a redirect
    forceLoginRedirect: () ->
      # when redirecting to login, if our attempted state is NOT `login`, set it as prior so that we know to redirect later
      if $state.current.name != 'login'
        rmapsPriorStateService.setPrior $state.current, $stateParams
      $state.go('login')

    # After a successful login, either go to the prior state or the map
    goToPostLoginState: () ->
      prior = rmapsPriorStateService.getPrior()

      if !$rootScope.principal?.isSubscriber() && !$rootScope.principal?.isProjectViewer()
        return $state.go('userSubscription')

      if prior
        $state.go(prior.state, prior.params, reload: true)

        # Clear the prior state
        rmapsPriorStateService.clearPrior()
        return

      $state.go('map', {id: rmapsProfilesService.currentProfile?.project_id}, {reload: true})

    # Ensure that this state change is correctly authenticated and authorized, or redirect to login
    # If the state requires a profile or a profile is specified on the URL, load it now
    authorize: ({event, toState, toParams}) ->
      $log.debug "authorize toState: #{toState.name}"
      if !toState?.permissionsRequired && !toState?.loginRequired
        # anyone can go to this state
        return

      # if we can, do check now (synchronously)
      if rmapsPrincipalService.isIdentityResolved()
        redirectState = doPermsCheck(toState, toParams)
        if redirectState
          redirect {state: redirectState, event}

        return

      # otherwise, go to temporary view and do check ASAP
      else
        rmapsPrincipalService.getIdentity()
        .then () ->
          redirectState = doPermsCheck(toState, toParams)
          if redirectState
            return redirect({state: redirectState})
          else
            # authentication and permissions are ok, return to your regularly scheduled program
            return redirect({state: toState, params: toParams})

        event?.preventDefault()
        return

  return service

app.run ($rootScope, rmapsMapAuthorizationFactory, rmapsEventConstants, $state, $log) ->
  $log = $log.spawn('router')
  $log.debug "attaching Map $stateChangeStart event"
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    $log.debug -> "$stateChangeStart: #{toState.name} params: #{JSON.stringify toParams} from: #{fromState?.name} params: #{JSON.stringify fromParams}"
    return rmapsMapAuthorizationFactory.authorize({event, toState, toParams, fromState, fromParams})

  $rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
    $log.debug -> "$stateChangeSuccess: to: #{toState.name} params: #{JSON.stringify toParams} from: #{fromState?.name} params: #{JSON.stringify fromParams}"
    return

  $rootScope.$on rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    $log.debug -> "profile.addremove: identity"
    rmapsMapAuthorizationFactory.authorize({event, toState: $state.current})
    return
