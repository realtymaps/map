app = require '../app.coffee'
_ = require 'lodash'

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

  $scope.pinResults = ($event) ->
    toPin = _.keys $scope.map.markers.filterSummary
    if _.isEmpty toPin
      toPin = _.keys $scope.map.markers.backendPriceCluster

    toPin = _.map toPin, (p) -> rm_property_id: p

    return unless toPin.length

    if confirm "Pin #{toPin.length} properties?"
      rmapsPropertiesService.saveProperty toPin

  $rootScope.$onRootScope rmapsevents.map.properties.pin, getPinned
  $rootScope.$onRootScope rmapsevents.map.properties.favorite, getFavorites
