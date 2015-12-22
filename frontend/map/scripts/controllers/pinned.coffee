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

    return unless toPin.length

    toPin = _.map toPin, (p) -> rm_property_id: p

    if confirm "Pin #{toPin.length} properties?"
      rmapsPropertiesService.pinProperty toPin

  $scope.unpinResults = ($event) ->
    toPin = _.keys $scope.map.markers.filterSummary
    if _.isEmpty toPin
      toPin = _.keys $scope.map.markers.backendPriceCluster

    return unless toPin.length

    toPin = _.map toPin, (p) -> rm_property_id: p

    if confirm "Unpin #{toPin.length} properties?"
      rmapsPropertiesService.unpinProperty toPin

  $rootScope.$onRootScope rmapsevents.map.properties.pin, getPinned
  $rootScope.$onRootScope rmapsevents.map.properties.favorite, getFavorites
