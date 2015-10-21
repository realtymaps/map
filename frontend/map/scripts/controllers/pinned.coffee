app = require '../app.coffee'
app.controller 'rmapsPinnedCtrl', ($scope, $rootScope, rmapsevents, rmapsprincipal, rmapsPropertiesService) ->

  $scope.pinned = {}

  getPinned = () ->
    rmapsprincipal.getIdentity()
    .then (identity) ->
      currentProfile = identity.profiles[identity.currentProfileId]
      $scope.pinned = _.extend {}, currentProfile.properties_selected
      for id, property of $scope.pinned
        rmapsPropertiesService.getPropertyDetail undefined, id, 'filter'
        .then (detail) ->
          _.extend property, detail

  $rootScope.registerScopeData getPinned

  $rootScope.$onRootScope 'profileSelected', getPinned
