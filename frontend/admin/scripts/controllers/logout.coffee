app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

###
  Logout controller
###
module.exports = app.controller 'LogoutCtrl'.ns(), () ->

# this controller manages loadingCount manually because we're putting an artificial min delay on logout,
# so it doesn't happen so quickly the user misses it.  We don't want to expose the illusion by having the
# Spinner go away more quickly

app.run ($rootScope, $location, $http, $timeout, rmapsprincipal, rmapsMainOptions, rmapsSpinner) ->
    $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
      # if we're not entering the logout state, or if we're already on the logout page, don't do anything
      if toState.url != adminRoutes.logout || fromState.url == adminRoutes.logout
        return
      minTimestamp = (+new Date)+rmapsMainOptions.logoutDelayMillis
      delayedUrl = (url) ->
        $timeout () ->
          rmapsSpinner.decrementLoadingCount("logout")
          $location.replace()
          $location.url url
        , minTimestamp-(+new Date)
      rmapsSpinner.incrementLoadingCount("logout")
      rmapsprincipal.getIdentity()
      .then () ->
        if not rmapsprincipal.isAuthenticated()
          delayedUrl($location.search().next || adminRoutes.index)
        else
          $http.get backendRoutes.userSession.logout
          .success (data, status) ->
            delayedUrl($location.search().next || adminRoutes.index)
          .finally ->
            rmapsprincipal.unsetIdentity()

        return
      return
