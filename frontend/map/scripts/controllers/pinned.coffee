app = require '../app.coffee'
app.controller 'rmapsPinnedCtrl', ($scope, $rootScope, rmapsevents, rmapsprincipal, rmapsPropertiesService) ->

  $scope.pinnedProperties = {}

  getPinned = (event, pinned) ->
    $scope.pinnedProperties = pinned or rmapsPropertiesService.getSavedProperties()

  $rootScope.registerScopeData getPinned

  $rootScope.$onRootScope rmapsevents.map.properties.updated, getPinned
