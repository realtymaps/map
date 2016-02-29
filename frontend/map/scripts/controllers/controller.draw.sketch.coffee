app = require '../app.coffee'
mapId = 'mainMap'

app.controller "rmapsDrawSketchCtrl", (
$scope, $log, $rootScope, rmapsEventConstants
rmapsNgLeafletEventGateService, rmapsDrawnService
rmapsMapDrawHandlesFactory, rmapsDrawCtrlFactory,
rmapsDrawPostActionFactory) ->

  $log = $log.spawn("map:rmapsDrawSketchCtrl")

  drawnShapesSvc = rmapsDrawnService.getDrawnShapesSvc()

  rmapsDrawnService.getDrawnItems().then (drawnItems) ->
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    handles = rmapsMapDrawHandlesFactory {
      drawnShapesSvc
      drawnItems
      endDrawAction: () ->
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
      commonPostDrawActions: rmapsDrawPostActionFactory($scope)
      announceCb: () ->
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
    }

    rmapsDrawCtrlFactory {
      mapId
      $scope
      handles
      drawnItems
      postDrawAction: rmapsDrawPostActionFactory($scope)
      name: "sketch"
    }
