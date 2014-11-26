app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

###
  Logout controller
###
module.exports = app.controller 'LogoutCtrl'.ourNs(), () ->

LOGOUT_DELAY = 1500

app.run ["$rootScope", "$location", "$http", "$timeout", "principal".ourNs(), ($rootScope, $location, $http, $timeout, principal) ->
  $rootScope.$on "$routeChangeStart", (event, nextRoute) ->
    # if we're entering the logout state, and we're already logged out, we'll skip it
    if nextRoute?.$$route?.originalPath != frontendRoutes.logout
      return
    minTimestamp = (+new Date)+LOGOUT_DELAY
    delayedUrl = (url) ->
      $timeout () ->
        $location.url url
      , minTimestamp-(+new Date)
    principal.getIdentity()
    .then () ->
      if not principal.isAuthenticated()
        delayedUrl(nextRoute.params.next || frontendRoutes.index)
      else
        $http.get backendRoutes.logout
        .success (data, status) ->
          principal.unsetIdentity()
          delayedUrl($location.search().next || frontendRoutes.index)
      return
    return
]
