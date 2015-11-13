app = require '../app.coffee'
app.controller 'rmapsPinnedCtrl', ($scope, $rootScope, rmapsevents, rmapsprincipal, rmapsPropertiesService) ->

  getPinned = (event, pinned) ->
    $scope.pinnedProperties = pinned or rmapsPropertiesService.getSavedProperties()
    $scope.pinnedTotal = _.keys($scope.pinnedProperties).length

  getFavorites = (event, favorites) ->
    $scope.favoriteProperties = favorites or rmapsPropertiesService.getFavoriteProperties()
    $scope.favoriteTotal = _.keys($scope.favoriteProperties).length

  $rootScope.registerScopeData () ->
    getPinned()
    getFavorites()

  $rootScope.$onRootScope rmapsevents.map.properties.pin, getPinned
  $rootScope.$onRootScope rmapsevents.map.properties.favorite, getFavorites

