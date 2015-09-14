app = require '../../app.coffee'

app.controller 'rmapsCountyCtrl',
($window, $scope, $rootScope) ->

  $scope.countyData =
    current: null

  $scope.countyConfigs = []

  $scope.getCountyList = () ->

  # Dropdown selection, reloads the view
  $scope.selectCounty = () ->
    $state.go($state.current, { id: $scope.countyData.current.id }, { reload: true })
