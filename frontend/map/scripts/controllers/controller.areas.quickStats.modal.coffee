###globals _###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.controller 'rmapsAreasQuickStatsModalCtrl', (
$scope
$uibModal
$http
$log
rmapsFilterManagerService
rmapsD3Stats) ->
  $log = $log.spawn("rmapsAreasQuickStatsModalCtrl")

  $scope.drawn = _.extend $scope.drawn || {},
    quickStats: null

  $scope.quickStats = (model) ->
    $log.debug 'quick stats', model
    filters = rmapsFilterManagerService.getFilters()
    geometry = _.extend(model.geometry, model.properties?.shape_extras)
    body = { state: {filters}, geometry }
    $http.post(backendRoutes.properties.inGeometry, body, cache: false)
    .then ({data}) ->
      $log.debug data
      $scope.areaToShow = id: 0, area_name: 'Quick'
      updateStatistics(data, 0, true)

  $scope.showStatistics = (model) ->
    $scope.areaToShow = model.properties
    $scope.centerOn(model)

    $http.post(backendRoutes.properties.drawnShapes,
      {
        areaId: $scope.areaToShow.id
        state:
          filters: rmapsFilterManagerService.getFilters()
      }
    ).then ({data}) ->
      updateStatistics(data, $scope.areaToShow.id)

  openModal = () ->
    modalInstance = $uibModal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/statisticsAreaStatus.jade')()

    modalInstance.result
    .then () ->
      $log.debug "saving layer", $scope.drawn.quickStats
      model = $scope.drawn.quickStats.toGeoJSON()
      model.properties.area_name = 'Untitle Area'
      $scope.signalUpdate $scope.drawnShapesSvc.create model
        .then (result) ->
          $log.debug result
          [id] = result.data
          id
      .then (id) ->
        $scope.checkToggleInShapes()
        $scope.drawn.quickStats.model =
          properties:
            id: id
    .catch () ->
      if $scope.drawn.quickStats
        $log.debug "deleting layer", $scope.drawn.quickStats
        $scope.drawn.items.removeLayer($scope.drawn.quickStats)


  updateStatistics = (data, area_id, showStatsSave) ->
    dataSet = _.values(data)

    stats = rmapsD3Stats.create(dataSet)
    stats = _.indexBy stats, 'key'
    $log.debug stats

    $scope.areaStatistics ?= {}
    $scope.areaStatistics[area_id] = stats

    $scope.showStatsSave = !!showStatsSave
    openModal()
