app = require '../app.coffee'

module.exports = app.controller 'MobilePageCtrl', ($scope) ->
  $scope.isMobileNavOpen = false

  $scope.toggleMobileNav = (event) ->
    event.stopPropagation() if event
    $scope.isMobileNavOpen = !$scope.isMobileNavOpen

  $scope.openMobileNav = (event) ->
    return if $scope.isMobileNavOpen
    event.stopPropagation()
    $scope.isMobileNavOpen = true

  $scope.closeMobileNav = (event) ->
    return if !$scope.isMobileNavOpen
    event.stopPropagation()
    $scope.isMobileNavOpen = false
