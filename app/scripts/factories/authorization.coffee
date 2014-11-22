# based on http://stackoverflow.com/questions/22537311/angular-ui-router-login-authentication

app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
permissionsUtil = require '../../../common/utils/permissions.coffee'

stringify = (obj) ->
  Object.keys(obj).map (key) ->
    return encodeURIComponent(key) + '=' + encodeURIComponent(obj[key])
  .join('&');

buildUrl = (path, params) ->
  "#{path}?#{stringify(params)}"
  
app.factory "authorization".ourNs(), ["$rootScope", "$location", "principal".ourNs(), ($rootScope, $location, principal) ->
  return authorize: (nextRoute) ->
    principal.getIdentity().then (identity) ->
      if not principal.isAuthenticated()
        if nextRoute?.$$route?.permissionsRequired || nextRoute.$$route.loginRequired
          # user is not authenticated, but needs to be.
          # set the route they wanted as a query parameter
          # then, send them to the signin route so they can log in
          $location.url buildUrl(frontendRoutes.login, next: buildUrl(nextRoute.$$route.originalPath, nextRoute.params))
          return
      
      if not permissionsUtil.checkAllowed(nextRoute?.$$route?.permissionsRequired, identity?.permissions, console.log)
        # user is signed in but not authorized for desired state
        $location.path frontendRoutes.accessDenied
        return
]

app.run ["$rootScope", "authorization".ourNs(), ($rootScope, authorization) ->
  $rootScope.$on "$routeChangeStart", (event, nextRoute) ->
    authorization.authorize(nextRoute)
    return
]
