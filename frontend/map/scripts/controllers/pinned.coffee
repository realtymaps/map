app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsPinnedCtrl', ($log, $scope, $rootScope, $modal, rmapsEventConstants, rmapsPrincipalService, rmapsPropertiesService) ->
  $log = $log.spawn('map:rmapsPinnedCtrl')

  getPinned = (event, eventData) ->
    pinned = eventData.properties if eventData

    $scope.pinnedProperties = pinned or rmapsPropertiesService.pins
    $scope.pinnedTotal = _.keys($scope.pinnedProperties).length

  getFavorites = (event, eventData) ->
    favorites = eventData.properties if favorites

    $scope.favoriteProperties = favorites or rmapsPropertiesService.favorites
    $scope.favoriteTotal = _.keys($scope.favoriteProperties).length

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
      rmapsPropertiesService.pinUnpinProperty toPin

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
      rmapsPropertiesService.pinUnpinProperty toPin

  $scope.getStatistics = () ->
    $log.debug "calculating pinned stats"
    $log.debug _.values($scope.pinnedProperties)
    stats = d3.nest()
    .key (d) ->
      # $log.debug d
      # $log.debug d.status
      d.status
    .rollup (status) ->
      # $log.debug status
      count: status.length
      price_avg: d3.mean(status, (p) -> p.price)
      sqft_avg: d3.mean(status, (p) -> p.sqft_finished)
      price_sqft_avg: d3.mean(status, (p) -> p.price/p.sqft_finished)
      days_on_market_avg: d3.mean(status, (p) -> p.days_on_market)
      acres_avg: d3.mean(status, (p) -> p.acres)
    .entries(_.values($scope.pinnedProperties))

    $log.debug stats
    stats = _.indexBy stats, 'key'
    $log.debug stats

    $scope.areaToShow = id: 'pinned', area_name: 'Pinned Properties'
    $scope.areaStatistics ?= {}
    $scope.areaStatistics.pinned = stats
    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/statisticsAreaStatus.jade')()

  $rootScope.$onRootScope rmapsEventConstants.update.properties.pin, getPinned
  $rootScope.$onRootScope rmapsEventConstants.update.properties.favorite, getFavorites

  getPinned()
  getFavorites()
