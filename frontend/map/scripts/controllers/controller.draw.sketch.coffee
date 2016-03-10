app = require '../app.coffee'
mapId = 'mainMap'
color = 'blue'

app.controller "rmapsDrawSketchCtrl", (
$scope, $log, $rootScope, rmapsEventConstants
rmapsNgLeafletEventGateService, rmapsDrawnUtilsService
rmapsMapDrawHandlesFactory, rmapsDrawCtrlFactory) ->

  $log = $log.spawn("map:rmapsDrawSketchCtrl")

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItems().then (drawnItems) ->
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    _handles = rmapsMapDrawHandlesFactory {
      drawnShapesSvc
      drawnItems
      endDrawAction: () ->
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
      commonPostDrawActions: () ->
        $scope.$emit rmapsEventConstants.map.mainMap.redraw

      announceCb: () ->
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
    }

    _drawCtrlFactory = (handles) ->
      rmapsDrawCtrlFactory({
        mapId
        $scope
        handles
        drawnItems
        postDrawAction: () ->
          $scope.$emit rmapsEventConstants.map.mainMap.redraw
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

        $rootScope.$onRootScope rmapsEventConstants.neighbourhoods.dropdownToggled, (event, isOpen) ->
          $scope.draw.show = !isOpen

    $scope.$watch 'Toggles.isSketchMode', (newVal) ->
      if newVal
        return _drawCtrlFactory(_handles)
      _drawCtrlFactory()
