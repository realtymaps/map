app = require '../app.coffee'
mapId = 'mainMap'

app.controller "rmapsDrawNeighborhoodCtrl", (
$scope, $log, $rootScope, rmapsEventConstants
rmapsNgLeafletEventGateService, rmapsDrawnService
rmapsMapDrawHandlesFactory, rmapsDrawCtrlFactory,
rmapsDrawPostActionFactory) ->
  $log = $log.spawn("map:rmapsDrawNeighborhoodCtrl")

  drawnShapesSvc = rmapsDrawnService.getDrawnShapesSvc()

  rmapsDrawnService.getDrawnItemsNeighborhoods().then (drawnItems) ->
    #filter drawItems which are only neighborhoods / frontend or backend
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    rmapsDrawnService.eachLayerModel

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
      name: "neighborhood"
      colorOptions:
        fillColor: 'red'
    }
