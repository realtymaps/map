app = require '../app.coffee'
color = 'blue'

app.controller "rmapsDrawSketchCtrl", (
  $scope,
  $log,
  $rootScope,
  rmapsEventConstants,
  rmapsDrawnUtilsService
  rmapsDrawCtrlFactory
  rmapsFeatureGroupUtil
  rmapsCurrentMapService
) ->
  $log = $log.spawn("map:rmapsDrawSketchCtrl")

  mapId = rmapsCurrentMapService.mainMapId()
  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItems().then (drawnItems) ->
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    featureGroupUtil = new rmapsFeatureGroupUtil({featureGroup:drawnItems, ownerName: 'rmapsDrawSketchCtrl', className: 'rmaps-sketch'})

    drawCtrl = rmapsDrawCtrlFactory({
      drawnShapesSvc
      featureGroupUtil
      mapId
      $scope
      handleOptions:
        commonPostDrawActions: () ->
          $scope.$emit rmapsEventConstants.map.mainMap.redraw
        # If we ever turn on tacking for sketches
        # createPromise: () ->
        #   if !$scope.Toggles.isTacks.sketch
        #     $scope.Toggles.isSketchMode = false
      drawnItems
      name: "sketch"
      itemsOptions:
        color: color
        fillColor: color
        className: 'rmaps-sketch'
      drawOptions:
        draw:
          polyline:
            shapeOptions: {color}
          polygon:
            shapeOptions: {color}
          rectangle:
            shapeOptions: {color}
          circle:
            shapeOptions: {color}
    })

    $scope.$watch 'Toggles.isSketchMode', (newVal) ->
      if newVal
        return drawCtrl.init(enable:true).then () ->
          $scope.draw.show = true

          $rootScope.$onRootScope rmapsEventConstants.areas.dropdownToggled, (event, isOpen) ->
            $scope.draw.show = !isOpen

      drawCtrl.init(enable:false)
