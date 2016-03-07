app = require '../app.coffee'
mapId = 'mainMap'

app.controller "rmapsDrawSketchCtrl", (
$scope, $log, $rootScope, rmapsEventConstants
rmapsNgLeafletEventGateService, rmapsDrawnUtilsService
rmapsMapDrawHandlesFactory, rmapsDrawCtrlFactory,
rmapsDrawPostActionFactory) ->

  $log = $log.spawn("map:rmapsDrawSketchCtrl")

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItems().then (drawnItems) ->
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    _handles = rmapsMapDrawHandlesFactory {
      drawnShapesSvc
      drawnItems
      endDrawAction: () ->
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
      commonPostDrawActions: rmapsDrawPostActionFactory($scope)
      announceCb: () ->
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
    }

    _drawCtrlFactory = (handles) ->
      rmapsDrawCtrlFactory {
        mapId
        $scope
        handles
        drawnItems
        postDrawAction: rmapsDrawPostActionFactory($scope)
        name: "sketch"
      }

    $scope.$watch 'Toggles.isSketchMode', (newVal) ->
      if newVal
        return _drawCtrlFactory(_handles)
      _drawCtrlFactory()
