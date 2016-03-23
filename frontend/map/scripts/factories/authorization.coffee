# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
app = require '../app.coffee'

app.factory 'rmapsAuthorizationFactory', ($rootScope, $timeout, $location, $log, $state, rmapsPrincipalService, rmapsProfilesService, rmapsUrlHelpersService) ->
  $log = $log.spawn('map:rmapsAuthorizationFactory')
  routes = rmapsUrlHelpersService.getRoutes()

  redirect = ({state, params, event, options}) ->
    #as stated in stackoverflow this avoids race hell in ui-router
    event?.preventDefault()

    $log.debug "Redirect to #{state.name || state}"
    $timeout ->
      $state.go state, params, options

  doPermsCheck = (toState, toParams) ->
    if not rmapsPrincipalService.isAuthenticated()
      # user is not authenticated, but needs to be.
      # $log.debug 'redirected to login'
      return routes.login

    if not rmapsPrincipalService.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      # $log.debug 'redirected to accessDenied'
      return routes.accessDenied

    if toState?.profileRequired and !rmapsProfilesService.currentProfile?
      # Determine if this route can load its own profile based on a state params
      if _.isString(toState.profileRequired) and toParams[toState.profileRequired]?
        return

      # $log.debug 'redirected to profiles'
      return routes.profiles

  return authorize: ({event, toState, toParams}) ->
    if !toState?.permissionsRequired && !toState?.loginRequired
      # anyone can go to this state
      return

    # if we can, do check now (synchronously)
    if rmapsPrincipalService.isIdentityResolved()
      redirectState = doPermsCheck(toState, toParams)
      if redirectState
        redirect {state: redirectState, event}

    # otherwise, go to temporary view and do check ASAP
    else
      redirect {state: routes.authenticating, event, options: notify: false}

      rmapsPrincipalService.getIdentity()
      .then (identity) ->
        return rmapsProfilesService.setCurrentProfileByIdentity identity
      .then () ->
        redirectState = doPermsCheck(toState, toParams)
        if redirectState
          redirect {state: redirectState}
        else
          # authentication and permissions are ok, return to your regularly scheduled program
          redirect {state: toState, params: toParams}

app.run ($rootScope, rmapsAuthorizationFactory, rmapsEventConstants, $state, $log) ->
  $log = $log.spawn('map:router')
  $log.debug "attaching $stateChangeStart event"
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    $log.debug -> "$stateChangeStart: #{toState.name} params: #{JSON.stringify toParams} from: #{fromState?.name} params: #{JSON.stringify fromParams}"
    rmapsAuthorizationFactory.authorize({event, toState, toParams, fromState, fromParams})
    return

  $rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
    $log.debug -> "$stateChangeSuccess: to: #{toState.name} params: #{JSON.stringify toParams} from: #{fromState?.name} params: #{JSON.stringify fromParams}"
    return

  $rootScope.$on rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    $log.debug -> "profile.addremove: identity"
    rmapsAuthorizationFactory.authorize {event, toState: $state.current}
