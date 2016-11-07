app = require '../app.coffee'
_ = require 'lodash'
d3 = require 'd3'

app.controller 'rmapsPinnedCtrl', (
$log
$scope
$rootScope
$uibModal
rmapsEventConstants
rmapsPropertiesService
rmapsD3Stats
) ->
  $log = $log.spawn('map:rmapsPinnedCtrl')

  $scope.pinResults = (action = 'Pin') ->
    toPin = $scope.formatters.results.getResultsArray()

    return unless toPin?.length

    if toPin.length == 1
      $scope.modalTitle = "#{action} #{toPin.length} Property?"
    else
      $scope.modalTitle = "#{action} #{toPin.length} Properties?"

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
    dataSet = _.values($rootScope.identity.currentProfile.pins)

    stats = rmapsD3Stats.create(dataSet)

    $log.debug stats

    $scope.areaToShow = id: 'pinned', area_name: 'Pinned Properties'
    $scope.areaStatistics ?= {}
    $scope.areaStatistics.pinned = stats
    $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/statisticsAreaStatus.jade')()
