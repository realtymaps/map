app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
alertIds = require '../../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../../common/utils/httpStatus.coffee'

###
  Login controller
###

module.exports = app.controller 'rmapsLoginCtrl',
  ($rootScope, $scope, $http, $location, rmapsprincipal, rmapsevents) ->

    $scope.form = {}
    $scope.doLoginPost = () ->
      $http.post backendRoutes.userSession.login, $scope.form
      .success (data, status) ->
        if !httpStatus.isWithinOK status
          return
        $rootScope.$emit rmapsevents.alert.dismiss, alertIds.loginFailure
        rmapsprincipal.setIdentity(data.identity)
        $location.replace()
        $location.url($location.search().next || adminRoutes.urls.mls)

app.run ($rootScope, $location, rmapsprincipal) ->

  doNextRedirect = (toState, nextLocation) ->
    if rmapsprincipal.isAuthenticated()
      $location.replace()
      $location.url(nextLocation || adminRoutes.urls.mls)

  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->

    # if we're entering the login state...
    if toState?.url != adminRoutes.login #toState.url is really just the state name here in admin
      return

    # ... and we're already logged in, we'll move past the login state (now or when we find out)
    if rmapsprincipal.isIdentityResolved()

      doNextRedirect(toState, $location.search().next)
    else
      rmapsprincipal.getIdentity()
      .then () ->
        doNextRedirect(toState, $location.search().next)