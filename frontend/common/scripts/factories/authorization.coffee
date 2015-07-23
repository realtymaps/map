# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
urlHelpers = require '../utils/util.urlHelpers.coffee'
qs = require 'qs'

module.exports = ($rootScope, $location, rmapsprincipal) ->

  routes = urlHelpers.getRoutes($location)

  doPermsCheck = (toState, desiredLocation, goToLocation) ->
    console.log "#### doPermsCheck"
    if not rmapsprincipal.isAuthenticated()
      # user is not authenticated, but needs to be.
      # set the route they wanted as a query parameter
      # then, send them to the signin route so they can log in
      $location.replace()
      console.log "#### ... not isAuthenticated, going to " + routes.login + '?'+qs.stringify(next: desiredLocation)
      $location.url routes.login + '?'+qs.stringify(next: desiredLocation)
      return

    if not rmapsprincipal.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      $location.replace()
      console.log "#### ... not hasPermission, going to " + routes.accessDenied
      $location.url routes.accessDenied
      return

    if goToLocation
      # check if we're in authenticating state if authenticating path is substring in location-path
      # (switched to regex here so we don't need to worry about matching leading slash)
      if ///#{routes.authenticating}$///.test($location.path())
        $location.replace()
      console.log "#### ... goToLocation = " + goToLocation + ", going to " + desiredLocation
      $location.url desiredLocation


  return authorize: (toState, toParams, fromState, fromParams) ->
    console.log "\n#### authorize"
    if !toState?.permissionsRequired && !toState?.loginRequired
      # anyone can go to this state
      return

    desiredLocation = $location.path()+'?'+qs.stringify($location.search())

    # if we can, do check now (synchronously)
    if rmapsprincipal.isIdentityResolved()
      return doPermsCheck(toState, desiredLocation, false)
    # otherwise, go to temporary view and do check ASAP
    $location.replace()
    console.log "#### authorize, going to temporary authenticating view: " + routes.authenticating
    $location.url routes.authenticating
    rmapsprincipal.getIdentity().then () ->
      return doPermsCheck(toState, desiredLocation, true)
