frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

#maydya .js
module.exports = (app) ->
  ###Bootstrap UI controllers###

  app.controller 'DropdownCtrl', ($rootScope, $scope, rmapsPrincipalService) ->
    $scope.isOpened = false
    $scope.status = isopen: false

    rmapsPrincipalService.getIdentity()
    .then (identity) ->
      # setting user to $rootScope since this is where a reference to user is used in other parts of the app
      $rootScope.user = identity.user

    $scope.toggleDropdown = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.status.isopen = !$scope.status.isopen
      $scope.isOpened = !$scope.isOpened
      return

    $scope.toggled = (open) ->
      $scope.isOpened = open

  .controller 'rmapsHistoryCtrl', ($scope, $http) ->
    $scope.historyArray = []

    ###emails json###

    $http.get(frontendRoutes.mocks.history).success((response) ->
      $scope.historyArray = response
    ).error (data, status, headers, config) ->
      alert status
