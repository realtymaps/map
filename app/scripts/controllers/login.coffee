app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

###
  Login controller
###
module.exports = app.controller 'LoginCtrl'.ourNs(), [
  '$scope', '$http', '$location', "principal".ourNs(), ($scope, $http, $location, principal) ->
    $scope.form = {}
    $scope.doLoginPost = () ->
      $scope.errorMessage = ""
      $http.post backendRoutes.login, $scope.form
      .success (data, status) ->
        principal.setIdentity(data.identity)
        $location.url($location.search().next || frontendRoutes.map)
      .error (data, status) ->
        $scope.errorMessage = data.error || "An unexpected error occurred. Please try again later."
]

app.run ["$rootScope", "$location", "principal".ourNs(), ($rootScope, $location, principal) ->
  
  doNextRedirect = (toState, nextLocation) ->
    if principal.isAuthenticated()
      $location.url(nextLocation || frontendRoutes.map)

  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->

    # if we're entering the login state...
    if toState?.url != frontendRoutes.login
      return
    
    # ... and we're already logged in, we'll skip the login state (now or when we find out)
    if principal.isIdentityResolved()
      doNextRedirect(toState, $location.search().next)
    else
      principal.getIdentity()
      .then () ->
        doNextRedirect(toState, $location.search().next)
]
