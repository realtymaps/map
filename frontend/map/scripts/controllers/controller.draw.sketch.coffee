app = require '../app.coffee'
color = 'blue'

app.controller "rmapsDrawSketchCtrl", (
  $scope,
  $log,
  $rootScope,
  rmapsEventConstants,
  rmapsDrawnUtilsService
  rmapsMapDrawHandlesFactory,
  rmapsMapIds
  rmapsDrawCtrlFactory
) ->
  $log = $log.spawn("map:rmapsDrawSketchCtrl")

  mapId = rmapsMapIds.mainMap()
  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItems().then (drawnItems) ->
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    _handles = rmapsMapDrawHandlesFactory {
      mapId
      drawnShapesSvc
      drawnItems
      commonPostDrawActions: () ->
        $scope.$emit rmapsEventConstants.map.mainMap.redraw
    }

    _drawCtrlFactory = (handles) ->
      rmapsDrawCtrlFactory({
        mapId
        $scope
        handles
        drawnItems
        name: "sketch"
        itemsOptions:
          color: color
          fillColor: color
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
      .then () ->
        $scope.draw.show = true

        $rootScope.$onRootScope rmapsEventConstants.areas.dropdownToggled, (event, isOpen) ->
          $scope.draw.show = !isOpen

    $scope.$watch 'Toggles.isSketchMode', (newVal) ->
      if newVal
        return _drawCtrlFactory(_handles)
      _drawCtrlFactory()
