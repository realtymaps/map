app = require '../app.coffee'
mapId = 'mainMap'
color = 'red'

app.controller "rmapsDrawNeighborhoodCtrl", (
$scope, $log, $rootScope, rmapsEventConstants, rmapsDrawnUtilsService
rmapsMapDrawHandlesFactory, rmapsDrawCtrlFactory) ->

  $log = $log.spawn("map:rmapsDrawNeighborhoodCtrl")

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  drawnShapesSvc.getDrawnItemsNeighborhoods().then (drawnItems) ->
    #filter drawItems which are only neighborhoods / frontend or backend
    $log.spawn("drawnItems").debug(Object.keys(drawnItems._layers).length)

    if !Object.keys(drawnItems._layers).length
      # There are zero neighborhoods, force propertiesInShapes to false
      $scope.Toggles.propertiesInShapes = false
      $rootScope.propertiesInShapes = false

    _handles = rmapsMapDrawHandlesFactory {
      mapId
      drawnShapesSvc
      drawnItems
      endDrawAction: () ->

      commonPostDrawActions: () ->
        $scope.$emit rmapsEventConstants.map.mainMap.redraw

      announceCb: () ->

      createPromise: (geoJson) ->
        #requires rmapsNeighbourhoodsModalCtrl to be in scope (parent)
        $scope.create(geoJson).then ->
          $scope.$emit rmapsEventConstants.map.mainMap.redraw
    }

    _drawCtrlFactory = (handles) ->
      rmapsDrawCtrlFactory {
        mapId
        $scope
        handles
        drawnItems
        postDrawAction: ->
          $scope.$emit rmapsEventConstants.map.mainMap.redraw
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
