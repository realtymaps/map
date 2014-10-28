app = require '../app.coffee'
###
  Login controller
###
module.exports = app.controller 'LoginCtrl'.ourNs(), [
  '$scope', '$http', '$location', ($scope, $http, $location) ->
    $scope.form = {}
    $scope.doLoginPost = () ->
      $http.post '/login', $scope.form
      .success (data, status) ->
        $location.path(data.destinationUrl);
      .error (data, status) ->
        $scope.errorMessage = data.error || "An unexpected error occurred. Please try again later."
]
