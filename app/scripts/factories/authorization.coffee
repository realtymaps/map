# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication

app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
permissionsUtil = require '../../../common/utils/permissions.coffee'

qs = require 'qs'


app.factory "authorization".ourNs(), ["$rootScope", "$location", "principal".ourNs(), ($rootScope, $location, principal) ->
  return authorize: (toState, toParams, fromState, fromParams) ->
    principal.getIdentity().then (identity) ->
      if not principal.isAuthenticated()
        if toState?.permissionsRequired || toState?.loginRequired
          # user is not authenticated, but needs to be.
          # set the route they wanted as a query parameter
          # then, send them to the signin route so they can log in
          $location.url frontendRoutes.login+'?'+qs.stringify(next: $location.path()+'?'+qs.stringify($location.search()))
          return
      
      if not permissionsUtil.checkAllowed(toState?.permissionsRequired, identity?.permissions, console.log)
        # user is signed in but not authorized for desired state
        $location.path frontendRoutes.accessDenied
        return
]

app.run ["$rootScope", "authorization".ourNs(), ($rootScope, authorization) ->
  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
    authorization.authorize(toState, toParams, fromState, fromParams)
    return
]
