app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.factory 'rmapsLogoutFactory', (
$timeout
$http
$rootScope
$state
rmapsPrincipalService
rmapsProfilesService
rmapsSpinnerService
rmapsMainOptions
) ->
  (logoutStr = 'logout') ->
    # this controller manages loadingCount manually because we're putting an artificial min delay on logout,
    # so it doesn't happen so quickly the user misses it.  We don't want to expose the illusion by having the
    # Spinner go away more quickly
    minTimestamp = (+new Date)+rmapsMainOptions.logoutDelayMillis

    delayedUrl = () ->
      $timeout () ->
        rmapsSpinnerService.decrementLoadingCount(logoutStr)
        if $state.current.name != 'login'
          $state.go('main')
      , minTimestamp-(+new Date)


    logout = () ->
      rmapsSpinnerService.incrementLoadingCount logoutStr
      rmapsPrincipalService.getIdentity()
      .then () ->
        if not rmapsPrincipalService.isAuthenticated()
          delayedUrl()
        else
          $http.get(backendRoutes.userSession.logout)
          .then ({data, status}) ->
            delayedUrl()
          .finally ->
            $rootScope.user = null
            rmapsPrincipalService.unsetIdentity()
            rmapsProfilesService.unsetCurrentProfile()

    {
      logout
      delayedUrl
    }
