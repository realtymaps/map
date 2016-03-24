# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
app = require '../app.coffee'

app.factory 'rmapsMapAuthorizationFactory', ($rootScope, $timeout, $location, $log, $state, rmapsPrincipalService, rmapsProfilesService, rmapsUrlHelpersService) ->
  $log = $log.spawn('map:rmapsMapAuthorizationFactory')
  routes = rmapsUrlHelpersService.getRoutes()

  redirect = ({state, params, event, options}) ->
    #as stated in stackoverflow this avoids race hell in ui-router
    event?.preventDefault()

    $log.debug "Redirect to #{state.name || state}"
    return $state.go state, params, options

  doPermsCheck = (toState, toParams) ->
    if not rmapsPrincipalService.isAuthenticated()
      # user is not authenticated, but needs to be.
      # $log.debug 'redirected to login'
      return routes.login

    if not rmapsPrincipalService.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      # $log.debug 'redirected to accessDenied'
      return routes.accessDenied

  return authorize: ({event, toState, toParams}) ->
    $log.debug "authorize toState: #{toState.name}"
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
      # Does the state or location define a project id?
      if toState.projectParam? and toParams[toState.projectParam]?
        $log.debug "Loading project based on toState.projectParam #{toState.projectParam}"
        project_id = Number(toParams[toState.projectParam])

      else if $location.search().project_id?
        $log.debug "Loading project based on ?project_id"
        project_id = Number($location.search().project_id)

      rmapsPrincipalService.getIdentity()
      .then (identity) ->
        # Determine if the state defined project exists
        if project_id?
          profile = (_.find(identity.profiles, project_id: project_id))

        # Does the defined project exist?
        if profile?
          $log.debug "Set current profile to", profile
          return rmapsProfilesService.setCurrentProfile profile
        else
          # Default to the session profile or the first profile for the identity
          $log.debug "Loading profile based on identity.currentProfileId #{identity.currentProfileId}"
          return rmapsProfilesService.setCurrentProfileByIdentity identity

      .then () ->
        redirectState = doPermsCheck(toState, toParams)
        if redirectState
          redirect {state: redirectState}
        else
          # authentication and permissions are ok, return to your regularly scheduled program
          redirect {state: toState, params: toParams}

      redirect {state: routes.authenticating, event, options: notify: false}

app.run ($rootScope, rmapsMapAuthorizationFactory, rmapsEventConstants, $state, $log) ->
  $log = $log.spawn('map:router')
  $log.debug "attaching Map $stateChangeStart event"
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    $log.debug -> "$stateChangeStart: #{toState.name} params: #{JSON.stringify toParams} from: #{fromState?.name} params: #{JSON.stringify fromParams}"
    rmapsMapAuthorizationFactory.authorize({event, toState, toParams, fromState, fromParams})
    return

  $rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
    $log.debug -> "$stateChangeSuccess: to: #{toState.name} params: #{JSON.stringify toParams} from: #{fromState?.name} params: #{JSON.stringify fromParams}"
    return

  $rootScope.$on rmapsEventConstants.principal.profile.addremove, (event, identity) ->
    $log.debug -> "profile.addremove: identity"
    rmapsMapAuthorizationFactory.authorize {event, toState: $state.current}
