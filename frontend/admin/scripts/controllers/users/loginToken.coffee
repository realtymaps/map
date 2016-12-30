app = require '../../app.coffee'
backendRoutes = require '../../../../../common/config/routes.backend.coffee'

app.controller 'rmapsLoginTokenCtrl', ($scope, $http, $log, user) ->
  $log = $log.spawn 'rmapsLoginTokenCtrl'
  $scope.user = user

  $scope.getToken = () ->
    $http.post(backendRoutes.userSession.requestLoginToken, {email: user.email})
    .then ({data}) ->
      $log.debug data
      $scope.token = data
