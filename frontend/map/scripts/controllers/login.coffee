app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'
alertIds = require '../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../common/utils/httpStatus.coffee'

###
  Login controller
###
  
module.exports = app.controller 'LoginCtrl'.ourNs(), [
  '$rootScope', '$scope', '$http', '$location', "principal".ourNs(), 'events'.ourNs(),
  ($rootScope, $scope, $http, $location, principal, Events) ->
    $scope.form = {}
    $scope.doLoginPost = () ->
      $http.post backendRoutes.user.login, $scope.form
      .success (data, status) ->
        if !httpStatus.isWithinOK status
          return
        $rootScope.$emit Events.alert.dismiss, alertIds.loginFailure
        principal.setIdentity(data.identity)
        $location.replace()
        $location.url($location.search().next || frontendRoutes.map)
]

app.run ["$rootScope", "$location", "principal".ourNs(), ($rootScope, $location, principal) ->
  
  doNextRedirect = (toState, nextLocation) ->
    if principal.isAuthenticated()
      $location.replace()
      $location.url(nextLocation || frontendRoutes.map)

  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->

    # if we're entering the login state...
    if toState?.url != frontendRoutes.login
      return

    # ... and we're already logged in, we'll move past the login state (now or when we find out)
    if principal.isIdentityResolved()
      doNextRedirect(toState, $location.search().next)
    else
      principal.getIdentity()
      .then () ->
        doNextRedirect(toState, $location.search().next)
]
