app = require '../app.coffee'

app.controller 'rmapsProjectAreasCtrl', (
  $log
  $scope

  rmapsDrawnUtilsService
) ->
  $log = $log.spawn('rmapsProjectAreasCtrl')

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  #
  # Data access
  #

  getAll = (cache) ->
    drawnShapesSvc.getAreasNormalized(cache)
    .then (data) ->
      $scope.areas = data

  #
  # Initial data load
  #
  getAll()
