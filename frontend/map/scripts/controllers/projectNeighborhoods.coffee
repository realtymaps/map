###globals _###
app = require '../app.coffee'

app.controller 'rmapsProjectAreasCtrl', (
  $log
  $rootScope
  $scope

  rmapsDrawnUtilsService
  rmapsEventConstants
) ->
  $log = $log.spawn('rmapsProjectAreasCtrl')

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  $scope.remove = (model) ->
    _.remove($scope.projectModel.areas, model)

    drawnShapesSvc.delete model
    .then () ->
      $rootScope.emit rmapsEventConstants.areas
      $rootScope.$emit rmapsEventConstants.areas.removeDrawItem, model
      $rootScope.$emit rmapsEventConstants.map.mainMap.redraw, false
