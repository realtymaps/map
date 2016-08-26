app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsPinnedCtrl', ($log, $scope, $rootScope, $uibModal, rmapsEventConstants, rmapsPrincipalService, rmapsPropertiesService) ->
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

    modalInstance = $uibModal.open
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

    modalInstance = $uibModal.open
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
    dataSet = _.values($scope.pinnedProperties)

    stats = d3.nest()
    .key (d) ->
      d.status
    .rollup (status) ->
      valid_price = status.filter (p) -> p.price?
      valid_sqft = status.filter (p) -> p.sqft_finished?
      valid_price_sqft = status.filter (p) -> p.price? && p.sqft_finished?
      valid_dom = status.filter (p) -> p.days_on_market?
      valid_acres = status.filter (p) -> p.acres?
      count: status.length
      price_avg: d3.mean(valid_price, (p) -> p.price)
      price_n: valid_price.length
      sqft_avg: d3.mean(valid_sqft, (p) -> p.sqft_finished)
      sqft_n: valid_sqft.length
      price_sqft_avg: d3.mean(valid_price_sqft, (p) -> p.price/p.sqft_finished)
      price_sqft_n: valid_price_sqft.length
      days_on_market_avg: d3.mean(valid_dom, (p) -> p.days_on_market)
      days_on_market_n: valid_dom.length
      acres_avg: d3.mean(valid_acres, (p) -> p.acres)
      acres_n: valid_acres.length
    .entries(dataSet)

    $log.debug stats
    stats = _.indexBy stats, 'key'
    $log.debug stats

    $scope.areaToShow = id: 'pinned', area_name: 'Pinned Properties'
    $scope.areaStatistics ?= {}
    $scope.areaStatistics.pinned = stats
    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/statisticsAreaStatus.jade')()

  $rootScope.$onRootScope rmapsEventConstants.update.properties.pin, getPinned
  $rootScope.$onRootScope rmapsEventConstants.update.properties.favorite, getFavorites

  getPinned()
  getFavorites()
