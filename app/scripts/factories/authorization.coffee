# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication

app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'

qs = require 'qs'


app.factory "authorization".ourNs(), ["$rootScope", "$location", "principal".ourNs(), ($rootScope, $location, principal) ->
  
  doPermsCheck = (toState, desiredLocation) ->
      
    if not principal.isAuthenticated()
      # user is not authenticated, but needs to be.
      # set the route they wanted as a query parameter
      # then, send them to the signin route so they can log in
      $location.url frontendRoutes.login + if desiredLocation? then '?'+qs.stringify(next: desiredLocation) else ''
      return
    
    if not principal.hasPermission(toState?.permissionsRequired)
      # user is signed in but not authorized for desired state
      $location.url frontendRoutes.accessDenied
      return
    
    if desiredLocation?
      $location.url desiredLocation

      
  return authorize: (toState, toParams, fromState, fromParams) ->
    
    if !toState?.permissionsRequired && !toState?.loginRequired
      # anyone can go to this state
      return
    
    desiredLocation = $location.path()+'?'+qs.stringify($location.search())

    # if we can, do check now (synchronously)
    if principal.isIdentityResolved()
      return doPermsCheck(toState)
    
    # otherwise, go to temporary view and do check ASAP
    $location.url frontendRoutes.authenticating
    principal.getIdentity().then () ->
      return doPermsCheck(toState, desiredLocation)
]

app.run ["$rootScope", "authorization".ourNs(), ($rootScope, authorization) ->
  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
    authorization.authorize(toState, toParams, fromState, fromParams)
    return
]
