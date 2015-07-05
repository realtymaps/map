# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication

adminRoutes = require '../../../../common/config/routes.admin.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'

qs = require 'qs'


module.exports = ($rootScope, $location, rmapsprincipal) ->

  # Even though there are some states in routes that are represented with full urls,
  # we need to apply the NS (i.e. admin) to all urls if needed to maintain generalized usage here

  # _applyNs = (routeStates, ns='admin') ->
  #   return _.mapValues routeStates, (v) ->
  #     return if (/^\/admin/.test(v)) then v else "/#{ns}/#{v}" 

  _useUrls = (routeStates) ->
    if !routeStates.urls?
      throw new Error("'urls' must be defined for the routes of this namespace.")
    return routeStates.urls

  console.log "#### common authorization"
  console.log "#### getting routes"
  console.log "#### location.path():"
  console.log $location.path()
  routes = if /^\/admin/.test($location.path()) then _useUrls adminRoutes else frontendRoutes
  console.log "#### routes:"
  console.log routes

  doPermsCheck = (toState, desiredLocation, goToLocation) ->
    console.log "#### admin authorization doPermsCheck()"
    console.log "#### goToLocation:"
    console.log goToLocation
    console.log "#### desiredLocation:"
    console.log desiredLocation

    if not rmapsprincipal.isAuthenticated()
      console.log "#### not authenticated..."
      # user is not authenticated, but needs to be.
      # set the route they wanted as a query parameter
      # then, send them to the signin route so they can log in
      $location.replace()
      console.log "#### routes.login:"
      console.log routes.login
      $location.url routes.login + '?'+qs.stringify(next: desiredLocation)
      return

    if not rmapsprincipal.hasPermission(toState?.permissionsRequired)
      console.log "#### no permission..."
      # user is signed in but not authorized for desired state
      $location.replace()
      console.log "#### routes.accessDenied:"
      console.log routes.accessDenied
      $location.url routes.accessDenied
      return

    console.log "#### goToLocation:"
    console.log goToLocation
    console.log "#### desiredLocation:"
    console.log desiredLocation

    if goToLocation
      #console.log "#### location.path == routes.authenticating?  #{$location.path()} == /#{routes.authenticating} ?"
      # if $location.path() == "/#{routes.authenticating}"
      # check if we're in authenticating state if authenticating path is substring in location-path
      # (we don't need to worry about matching leading slash this way)
      console.log "#### t = ///#{routes.authenticating}$///.test($location.path())   ?"
      t = ///#{routes.authenticating}$///.test($location.path())
      console.log t
      if ///#{routes.authenticating}$///.test($location.path())
        $location.replace()
      $location.url desiredLocation


  return authorize: (toState, toParams, fromState, fromParams) ->
    console.log "#### authorize"
    console.log "#### path():"
    console.log $location.path()

    console.log "#### toState:"
    console.log toState
    console.log "#### toParams:"
    console.log toParams
    console.log "#### fromState:"
    console.log fromState
    console.log "#### fromParams:"
    console.log fromParams


    if !toState?.permissionsRequired && !toState?.loginRequired
      # anyone can go to this state
      return

    desiredLocation = $location.path()+'?'+qs.stringify($location.search())

    # if we can, do check now (synchronously)
    console.log "#### authorize desiredLocation:"
    console.log desiredLocation
    if rmapsprincipal.isIdentityResolved()
      return doPermsCheck(toState, desiredLocation, false)
    console.log "#### identity is not resolved"
    # otherwise, go to temporary view and do check ASAP
    $location.replace()
    $location.url routes.authenticating
    rmapsprincipal.getIdentity().then () ->
      return doPermsCheck(toState, desiredLocation, true)
