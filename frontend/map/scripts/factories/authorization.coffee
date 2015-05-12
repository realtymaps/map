# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication

app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'

qs = require 'qs'


app.factory "authorization".ourNs(), ["$rootScope", "$location", "principal".ourNs(), ($rootScope, $location, principal) ->
  
  doPermsCheck = (toState, desiredLocation, goToLocation) ->
      
    if not principal.isAuthenticated()
      # user is not authenticated, but needs to be.
      # set the route they wanted as a query parameter
      # then, send them to the signin route so they can log in
      $location.replace()
      $location.url frontendRoutes.login + '?'+qs.stringify(next: desiredLocation)
      return
    
    if not principal.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      $location.replace()
      $location.url frontendRoutes.accessDenied
      return
    
    if goToLocation
      if $location.path() == "/#{frontendRoutes.authenticating}"
        $location.replace()
      $location.url desiredLocation

      
  return authorize: (toState, toParams, fromState, fromParams) ->
    
    if !toState?.permissionsRequired && !toState?.loginRequired
      # anyone can go to this state
      return
    
    desiredLocation = $location.path()+'?'+qs.stringify($location.search())

    # if we can, do check now (synchronously)
    if principal.isIdentityResolved()
      return doPermsCheck(toState, desiredLocation, false)
    
    # otherwise, go to temporary view and do check ASAP
    $location.replace()
    $location.url frontendRoutes.authenticating
    principal.getIdentity().then () ->
      return doPermsCheck(toState, desiredLocation, true)
]

app.run ["$rootScope", "authorization".ourNs(), ($rootScope, authorization) ->
  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
    authorization.authorize(toState, toParams, fromState, fromParams)
    return
]
