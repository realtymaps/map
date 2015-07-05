app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

app.controller 'rmapsHomeCtrl', ($scope, $state, rmapsevents, rmapsprincipal) ->
  $scope.adminRoutes = adminRoutes
  $scope.$state = $state
  $scope.principal = rmapsprincipal
