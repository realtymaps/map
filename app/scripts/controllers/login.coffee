app = require '../app.coffee'
routes = require '../../../common/config/routes.coffee'

###
  Login controller
###
module.exports = app.controller 'LoginCtrl'.ourNs(), [
  '$scope', '$http', '$location', ($scope, $http, $location) ->
    $scope.form = {}
    $scope.doLoginPost = () ->
      $http.post routes.logIn+'?next='+$location.search().next, $scope.form
      .success (data, status) ->
        $location.search "next", null
        $location.path data.redirectUrl
      .error (data, status) ->
        $scope.errorMessage = data.error || "An unexpected error occurred. Please try again later."
]
