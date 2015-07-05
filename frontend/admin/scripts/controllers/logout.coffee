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

app.run ($rootScope, $location, $http, $timeout, rmapsprincipal, adminOptions) ->
    $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
      console.log "#### stateChange to logout"
      # if we're not entering the logout state, or if we're already on the logout page, don't do anything
      if toState.url != adminRoutes.logout || fromState.url == adminRoutes.logout
        return
      minTimestamp = (+new Date)+adminOptions.logoutDelayMillis
      $rootScope.loadingCount = 1
      delayedUrl = (url) ->
        $timeout () ->
          $location.replace()
          $location.url url
        , minTimestamp-(+new Date)
      rmapsprincipal.getIdentity()
      .then () ->
        if not rmapsprincipal.isAuthenticated()
          console.log "#### not authenticated"
          delayedUrl($location.search().next || adminRoutes.index)
        else
          console.log "#### is authenticated"
          $http.get backendRoutes.userSession.logout
          .success (data, status) ->
            console.log "#### logout success, data:"
            console.log data
            console.log "#### status:"
            console.log status
            delayedUrl($location.search().next || adminRoutes.index)
          .finally ->
            rmapsprincipal.unsetIdentity()
            $rootScope.loadingCount = 0
            console.log "#### identity unset, loadingCount == 0"

        return
      return
