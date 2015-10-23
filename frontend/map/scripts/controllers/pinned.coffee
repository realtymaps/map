app = require '../app.coffee'
app.controller 'rmapsPinnedCtrl', ($scope, $rootScope, rmapsevents, rmapsprincipal, rmapsPropertiesService) ->

  getPinned = (event, pinned) ->
    $scope.pinnedProperties = pinned or rmapsPropertiesService.getSavedProperties()
    $scope.pinnedTotal = _.keys($scope.pinnedProperties).length

  $rootScope.registerScopeData getPinned

  $rootScope.$onRootScope rmapsevents.map.properties.updated, getPinned
