app = require '../app.coffee'
mapId = 'mainMap'

app.controller "rmapsDrawNeighborhoodCtrl", (
$scope, $log, $rootScope, rmapsEventConstants
rmapsNgLeafletEventGateService, rmapsDrawnUtilsService
rmapsMapDrawHandlesFactory, rmapsDrawCtrlFactory,
rmapsDrawPostActionFactory) ->

  $log = $log.spawn("map:rmapsDrawNeighborhoodCtrl")

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItemsNeighborhoods().then (drawnItems) ->
    #filter drawItems which are only neighborhoods / frontend or backend
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    if Object.keys(drawnItems._layers).length
      unWatch = $scope.$watch 'Toggles', (newVal) ->
        if newVal
          $scope.Toggles.propertiesInShapes = true
          unWatch()

    _handles = rmapsMapDrawHandlesFactory {
      drawnShapesSvc
      drawnItems
      endDrawAction: () ->
        rmapsNgLeafletEventGateService.enableMapCommonEvents(mapId)
      commonPostDrawActions: rmapsDrawPostActionFactory($scope)
      announceCb: () ->
        rmapsNgLeafletEventGateService.disableMapCommonEvents(mapId)
      create: $scope.create #requires rmapsNeighbourhoodsModalCtrl to be in scope (parent)
    }

    _drawCtrlFactory = (handles) ->
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

    $scope.$watch 'Toggles.isNeighborhoodDraw', (newVal) ->
      if newVal
        return _drawCtrlFactory(_handles)
      _drawCtrlFactory()
