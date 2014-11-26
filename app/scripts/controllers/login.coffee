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
      $scope.errorMessage = "";
      $http.post backendRoutes.login, $scope.form
      .success (data, status) ->
        principal.setIdentity(data.identity)
        $location.url($location.search().next || frontendRoutes.map)
      .error (data, status) ->
        $scope.errorMessage = data.error || "An unexpected error occurred. Please try again later."
]

app.run ["$rootScope", "$location", "principal".ourNs(), ($rootScope, $location, principal) ->
  $rootScope.$on "$routeChangeStart", (event, nextRoute) ->
    # if we're entering the login state, and we're already logged in, we'll skip it
    principal.getIdentity()
    .then () ->
      if nextRoute?.$$route?.originalPath == frontendRoutes.login && principal.isAuthenticated()
        $location.url(nextRoute.params.next || frontendRoutes.map)
      return
    return
]
