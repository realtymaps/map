app = require '../app.coffee'
mapId = 'mainMap'
color = 'red'

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
      unWatch = $scope.$watchCollection 'Toggles', (newVal) ->
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
      createPromise: (geoJson) ->
        #requires rmapsNeighbourhoodsModalCtrl to be in scope (parent)
        $scope.create(geoJson).then ->
          $scope.$emit rmapsEventConstants.map.redraw
    }

    _drawCtrlFactory = (handles) ->
      rmapsDrawCtrlFactory {
        mapId
        $scope
        handles
        drawnItems
        postDrawAction: rmapsDrawPostActionFactory($scope)
        name: "neighborhood"
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
      }

    $scope.$watch 'Toggles.isNeighborhoodDraw', (newVal) ->
      if newVal
        return _drawCtrlFactory(_handles)
      _drawCtrlFactory()
