app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsPinnedCtrl', ($log, $scope, $rootScope, $modal, rmapsEventConstants, rmapsPrincipalService, rmapsPropertiesService) ->
  $log = $log.spawn('map:rmapsPinnedCtrl')

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
    toPin = $scope.formatters.results.getResultsArray()
    $log.debug toPin

    return unless toPin?.length

    if toPin.length == 1
      $scope.modalTitle = "Pin #{toPin.length} Property?"
    else
      $scope.modalTitle = "Pin #{toPin.length} Properties?"

    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/confirm.jade')()

    $scope.modalCancel = () ->
      modalInstance.dismiss('cancel')

    $scope.modalOk = () ->
      modalInstance.dismiss('ok')
      rmapsPropertiesService.pinProperty toPin

  $scope.unpinResults = ($event) ->
    toPin = $scope.formatters.results.getResultsArray()

    return unless toPin?.length

    if toPin.length == 1
      $scope.modalTitle = "Unpin #{toPin.length} Property?"
    else
      $scope.modalTitle = "Unpin #{toPin.length} Properties?"

    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/confirm.jade')()

    $scope.modalCancel = () ->
      modalInstance.dismiss('cancel')

    $scope.modalOk = () ->
      modalInstance.dismiss('ok')
      rmapsPropertiesService.unpinProperty toPin

  $rootScope.$onRootScope rmapsEventConstants.update.properties.pin, getPinned
  $rootScope.$onRootScope rmapsEventConstants.update.properties.favorite, getFavorites
