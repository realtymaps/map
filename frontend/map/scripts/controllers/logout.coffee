app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

###
  Logout controller
###
module.exports = app.controller 'rmapsLogoutCtrl', () ->
logoutStr = 'logout'
# this controller manages loadingCount manually because we're putting an artificial min delay on logout,
# so it doesn't happen so quickly the user misses it.  We don't want to expose the illusion by having the
# Spinner go away more quickly

app.run ($rootScope, $location, $http, $timeout, $window, rmapsPrincipalService, rmapsMainOptions, rmapsSpinnerService) ->
  $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
    # if we're not entering the logout state, or if we're already on the logout page, don't do anything
    if toState.url != frontendRoutes.logout || fromState.url == frontendRoutes.logout
      return
    minTimestamp = (+new Date)+rmapsMainOptions.logoutDelayMillis
    delayedUrl = (url) ->
      $timeout () ->
        rmapsSpinnerService.decrementLoadingCount logoutStr
        $location.replace()
        $window.location.href = url
      , minTimestamp-(+new Date)
    rmapsSpinnerService.incrementLoadingCount logoutStr
    rmapsPrincipalService.getIdentity()
    .then () ->
      if not rmapsPrincipalService.isAuthenticated()
        delayedUrl($location.search().next || frontendRoutes.index)
      else
        $http.get backendRoutes.userSession.logout
        .success (data, status) ->
          delayedUrl($location.search().next || frontendRoutes.index)
        .finally ->
          rmapsPrincipalService.unsetIdentity()

      return
    return
