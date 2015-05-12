app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

###
  Logout controller
###
module.exports = app.controller 'LogoutCtrl'.ourNs(), () ->

# this controller manages loadingCount manually because we're putting an artificial min delay on logout,
# so it doesn't happen so quickly the user misses it.  We don't want to expose the illusion by having the
# spinner go away more quickly

app.run ["$rootScope", "$location", "$http", "$timeout", "principal".ourNs(), 'MainOptions'.ourNs(), 'Spinner'.ourNs(),
  ($rootScope, $location, $http, $timeout, principal, MainOptions, Spinner) ->
    $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
      # if we're not entering the logout state, or if we're already on the logout page, don't do anything
      if toState.url != frontendRoutes.logout || fromState.url == frontendRoutes.logout
        return
      minTimestamp = (+new Date)+MainOptions.logoutDelayMillis
      delayedUrl = (url) ->
        $timeout () ->
          Spinner.decrementLoadingCount("logout")
          $location.replace()
          $location.url url
        , minTimestamp-(+new Date)
      Spinner.incrementLoadingCount("logout")
      principal.getIdentity()
      .then () ->
        if not principal.isAuthenticated()
          delayedUrl($location.search().next || frontendRoutes.index)
        else
          $http.get backendRoutes.user.logout
          .success (data, status) ->
            principal.unsetIdentity()
            delayedUrl($location.search().next || frontendRoutes.index)
        return
      return
]
