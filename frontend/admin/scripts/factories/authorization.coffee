app = require '../app.coffee'
authorization = require '../../../common/scripts/factories/authorization.coffee'
module.exports = app.factory 'rmapsauthorization', authorization

app.run ($rootScope, rmapsauthorization) ->
  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
    rmapsauthorization.authorize(toState, toParams, fromState, fromParams)
    return


# app = require '../app.coffee'
# authorization = require '../../../common/scripts/factories/authorization.coffee'
# module.exports = app.factory 'rmapsauthorization', authorization

# app.run ($rootScope, rmapsauthorization) ->
#   $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
#     rmapsauthorization.authorize(toState, toParams, fromState, fromParams)
#     return

# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication
# _ = require 'lodash'
# app = require '../app.coffee'
# adminRoutes = require '../../../../common/config/routes.frontend.coffee'

# qs = require 'qs'


# app.factory 'rmapsauthorization', ($rootScope, $location, rmapsprincipal) ->


#   _applyNs = (routeStates, ns='admin') ->
#     return _.mapValues routeStates, (v) ->
#       return if (/^\/admin/.test(v)) then v else "/#{ns}/#{v}" 

#   routes = _applyNs adminRoutes

#   doPermsCheck = (toState, desiredLocation, goToLocation) ->
#     console.log "#### admin authorization"
#     console.log "#### goToLocation:"
#     console.log goToLocation
#     console.log "#### goToLocation:"
#     console.log desiredLocation

#     if not rmapsprincipal.isAuthenticated()
#       console.log "#### not authenticated..."
#       # user is not authenticated, but needs to be.
#       # set the route they wanted as a query parameter
#       # then, send them to the signin route so they can log in
#       $location.replace()
#       console.log "#### routes.login:"
#       console.log routes.login
#       $location.url routes.login + '?'+qs.stringify(next: desiredLocation)
#       return

#     if not rmapsprincipal.hasPermission(toState?.permissionsRequired)
#       console.log "#### no permission..."
#       # user is signed in but not authorized for desired state
#       $location.replace()
#       console.log "#### routes.accessDenied:"
#       console.log routes.accessDenied
#       $location.url routes.accessDenied
#       return

#     console.log "#### goToLocation:"
#     console.log goToLocation
#     console.log "#### goToLocation:"
#     console.log desiredLocation

#     if goToLocation
#       if $location.path() == "/#{routes.authenticating}"
#         $location.replace()
#       $location.url desiredLocation


#   return authorize: (toState, toParams, fromState, fromParams) ->
#     #routes = _getRoutes()
#     console.log "#### routes:"
#     console.log routes
#     console.log "path()"
#     console.log $location.path()

#     if !toState?.permissionsRequired && !toState?.loginRequired
#       # anyone can go to this state
#       return

#     desiredLocation = $location.path()+'?'+qs.stringify($location.search())

#     # if we can, do check now (synchronously)
#     console.log "#### desiredLocation:"
#     console.log desiredLocation
#     if rmapsprincipal.isIdentityResolved()
#       return doPermsCheck(toState, desiredLocation, false)
#     console.log "#### identity is not resolved"
#     # otherwise, go to temporary view and do check ASAP
#     $location.replace()
#     $location.url routes.authenticating
#     rmapsprincipal.getIdentity().then () ->
#       return doPermsCheck(toState, desiredLocation, true)

# app.run ($rootScope, rmapsauthorization) ->
#   $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
#     rmapsauthorization.authorize(toState, toParams, fromState, fromParams)
#     return
