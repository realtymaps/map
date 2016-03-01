frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

#maydya .js
module.exports = (app) ->
  ###Bootstrap UI controllers###

  app.controller 'DropdownCtrl', ($scope) ->
    $scope.isOpened = false
    $scope.status = isopen: false

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
